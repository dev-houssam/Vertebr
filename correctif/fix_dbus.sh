#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_dbus.sh
# Injecte DBUS_SESSION_BUS_ADDRESS dans le service systemd
# sans écraser la configuration existante.
# Usage : sudo ./fix_dbus.sh
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix DBUS v1.0.3             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Vérifications préalables ─────────────────────────────────

if [ "$EUID" -ne 0 ]; then
    error "Lance ce script avec sudo : sudo ./fix_dbus.sh"
fi

SERVICE_FILE="/etc/systemd/system/vertebr.service"
if [ ! -f "$SERVICE_FILE" ]; then
    error "Service vertebr introuvable : $SERVICE_FILE"
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

info "Utilisateur : $REAL_USER (uid=$REAL_UID)"

# ── 1. Récupérer DBUS depuis /proc (méthode fiable sous sudo) ─

info "Recherche de DBUS_SESSION_BUS_ADDRESS..."

# Chercher dans les environnements de tous les processus de l'utilisateur
DBUS_VAL=$(
    for pid in $(ps -u "$REAL_UID" -o pid=); do
        cat /proc/"$pid"/environ 2>/dev/null
    done \
    | tr '\0' '\n' \
    | grep '^DBUS_SESSION_BUS_ADDRESS=' \
    | head -1 \
    | cut -d= -f2-
)

# Fallback : valeur standard pour uid=1000
if [ -z "$DBUS_VAL" ]; then
    DBUS_VAL="unix:path=/run/user/${REAL_UID}/bus"
    warn "DBUS non trouvé dans /proc — utilisation de la valeur standard : $DBUS_VAL"
else
    success "DBUS trouvé : $DBUS_VAL"
fi

# ── 2. Lire les autres variables du service actuel ───────────

info "Lecture du service existant..."

CURRENT_DISPLAY=$(grep    '^Environment=DISPLAY='        "$SERVICE_FILE" | cut -d= -f2-)
CURRENT_XAUTH=$(grep      '^Environment=XAUTHORITY='     "$SERVICE_FILE" | cut -d= -f2-)
CURRENT_PULSE=$(grep      '^Environment=PULSE_SERVER='   "$SERVICE_FILE" | cut -d= -f2-)
CURRENT_XDG=$(grep        '^Environment=XDG_RUNTIME_DIR=' "$SERVICE_FILE" | cut -d= -f2-)

# Valeurs par défaut si absentes
CURRENT_DISPLAY="${CURRENT_DISPLAY:-:0}"
CURRENT_XAUTH="${CURRENT_XAUTH:-/run/user/${REAL_UID}/gdm/Xauthority}"
CURRENT_PULSE="${CURRENT_PULSE:-unix:/run/user/${REAL_UID}/pulse/native}"
CURRENT_XDG="${CURRENT_XDG:-/run/user/${REAL_UID}}"

info "DISPLAY        = $CURRENT_DISPLAY"
info "XAUTHORITY     = $CURRENT_XAUTH"
info "DBUS           = $DBUS_VAL"
info "PULSE_SERVER   = $CURRENT_PULSE"
info "XDG_RUNTIME    = $CURRENT_XDG"

# ── 3. Écrire le service final avec toutes les valeurs ───────

info "Mise à jour du service (sans écraser les autres valeurs)..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Vertebr System Configuration Daemon
After=network.target dbus.service bluetooth.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/vertebr-daemon
ExecStartPost=/bin/chmod 777 /tmp/vertebr.sock
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=vertebr

# ── Daemon ────────────────────────────────────────────────
Environment=VERTEBR_CONFIG=/etc/vertebr/routes.toml
Environment=VERTEBR_MODULES=/usr/lib/vertebr/modules
Environment=VERTEBR_SOCKET=/tmp/vertebr.sock

# ── Environnement graphique ───────────────────────────────
Environment=DISPLAY=${CURRENT_DISPLAY}
Environment=XAUTHORITY=${CURRENT_XAUTH}
Environment=DBUS_SESSION_BUS_ADDRESS=${DBUS_VAL}
Environment=PULSE_SERVER=${CURRENT_PULSE}
Environment=XDG_RUNTIME_DIR=${CURRENT_XDG}
Environment=HOME=${REAL_HOME}

# ── CAPABILITIES ─────────────────────────────────────────
AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP
CapabilityBoundingSet=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP

[Install]
WantedBy=multi-user.target
EOF

success "Service écrit avec DBUS=$DBUS_VAL"

# ── 4. Vérification rapide ───────────────────────────────────

WRITTEN_DBUS=$(grep '^Environment=DBUS_SESSION_BUS_ADDRESS=' "$SERVICE_FILE" | cut -d= -f2-)
if [ -n "$WRITTEN_DBUS" ]; then
    success "Vérification : DBUS bien présent dans le service ✓"
else
    error "DBUS manquant après écriture — problème inattendu"
fi

# ── 5. Recharger systemd et redémarrer ───────────────────────

info "Rechargement de systemd..."
systemctl daemon-reload

info "Redémarrage du daemon Vertebr..."
systemctl restart vertebr
sleep 2

# ── 6. Corriger le socket ────────────────────────────────────

if [ -S /tmp/vertebr.sock ]; then
    chmod 777 /tmp/vertebr.sock
    success "Socket /tmp/vertebr.sock → 777"
else
    warn "Socket absent — attente 3s..."
    sleep 3
    if [ -S /tmp/vertebr.sock ]; then
        chmod 777 /tmp/vertebr.sock
        success "Socket apparu et corrigé"
    else
        warn "Socket toujours absent — vérifier les logs : journalctl -u vertebr -n 20"
    fi
fi

# ── 7. Test de communication ─────────────────────────────────

echo ""
info "Test de communication avec le daemon..."

if command -v socat &>/dev/null && [ -S /tmp/vertebr.sock ]; then
    RESP=$(echo '{"route":"wifi:status","payload":{}}' \
           | timeout 4 socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null | head -c 300)
    if echo "$RESP" | grep -q '"status"'; then
        success "Daemon répond : $RESP"
    else
        warn "Pas de réponse (modules peut-être en cours de chargement)"
    fi
else
    info "socat non disponible — test ignoré"
fi

# ── 8. Test gsettings (thème) ────────────────────────────────

THEME=$(DBUS_SESSION_BUS_ADDRESS="$DBUS_VAL" \
        XDG_RUNTIME_DIR="$CURRENT_XDG" \
        runuser -u "$REAL_USER" -- \
        gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)

if [ -n "$THEME" ]; then
    success "gsettings fonctionne → thème : $THEME"
else
    warn "gsettings ne répond pas encore"
fi

# ── 9. Test pactl (son) ──────────────────────────────────────

SINKS=$(XDG_RUNTIME_DIR="$CURRENT_XDG" \
        PULSE_SERVER="$CURRENT_PULSE" \
        runuser -u "$REAL_USER" -- \
        pactl list sinks short 2>/dev/null | wc -l)

if [ "$SINKS" -gt 0 ]; then
    success "pactl fonctionne → $SINKS sortie(s) audio détectée(s)"
else
    warn "pactl ne répond pas"
fi

# ── 10. Résumé ───────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅  fix_dbus terminé                              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Daemon   : $(systemctl is-active vertebr)"
echo "  Socket   : $([ -S /tmp/vertebr.sock ] && stat -c 'présent (perm: %a)' /tmp/vertebr.sock || echo 'absent')"
echo "  DBUS     : $WRITTEN_DBUS"
echo "  Modules  : $(ls /usr/lib/vertebr/modules/*.so 2>/dev/null | wc -l) .so chargés"
echo ""
echo "  Lance Electron :"
echo "    cd frontend"
echo "    npx electron@28 ../electron/main.js"
echo ""
