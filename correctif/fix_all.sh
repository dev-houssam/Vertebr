#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_all.sh
# Corrige : socket permanent + Son + Affichage
# Usage : sudo ./fix_all.sh
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix global v1.0.2           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Détecter l'utilisateur réel (même sous sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

info "Utilisateur détecté : $REAL_USER (uid=$REAL_UID, home=$REAL_HOME)"

# ── 1. Détecter DISPLAY et XAUTHORITY ───────────────────────
info "Détection de l'environnement graphique..."

# Chercher le DISPLAY actif
DISPLAY_VAL=$(su - "$REAL_USER" -c 'echo $DISPLAY' 2>/dev/null)
if [ -z "$DISPLAY_VAL" ]; then
    # Fallback : chercher dans /proc
    DISPLAY_VAL=$(grep -h DISPLAY /proc/*/environ 2>/dev/null | \
        tr '\0' '\n' | grep '^DISPLAY=' | head -1 | cut -d= -f2)
fi
DISPLAY_VAL="${DISPLAY_VAL:-:0}"

# Chercher XAUTHORITY
XAUTH_VAL=$(su - "$REAL_USER" -c 'echo $XAUTHORITY' 2>/dev/null)
if [ -z "$XAUTH_VAL" ] || [ ! -f "$XAUTH_VAL" ]; then
    # Chercher le fichier .Xauthority
    XAUTH_VAL="$REAL_HOME/.Xauthority"
    # Ou dans /run/user/
    if [ ! -f "$XAUTH_VAL" ]; then
        XAUTH_VAL=$(find /run/user/"$REAL_UID" -name ".mutter-Xwaylandauth*" \
            -o -name "Xauthority" 2>/dev/null | head -1)
    fi
fi

# Chercher DBUS_SESSION_BUS_ADDRESS
DBUS_VAL=$(su - "$REAL_USER" -c 'echo $DBUS_SESSION_BUS_ADDRESS' 2>/dev/null)
if [ -z "$DBUS_VAL" ]; then
    DBUS_VAL=$(grep -h DBUS_SESSION_BUS_ADDRESS /proc/*/environ 2>/dev/null | \
        tr '\0' '\n' | grep "^DBUS_SESSION_BUS_ADDRESS=" | \
        grep -v "^$" | head -1 | cut -d= -f2-)
fi

# PULSE_SERVER pour pactl
PULSE_SERVER_VAL="unix:/run/user/${REAL_UID}/pulse/native"
# Vérifier que le socket pulse existe
if [ ! -S "/run/user/${REAL_UID}/pulse/native" ]; then
    PULSE_SERVER_VAL=""
    warn "PulseAudio/PipeWire socket non trouvé pour uid=$REAL_UID"
fi

info "DISPLAY        = $DISPLAY_VAL"
info "XAUTHORITY     = $XAUTH_VAL"
info "DBUS           = ${DBUS_VAL:-(non trouvé)}"
info "PULSE_SERVER   = ${PULSE_SERVER_VAL:-(non trouvé)}"

# ── 2. Réécrire le service systemd ──────────────────────────
info "Mise à jour du service systemd..."

cat > /etc/systemd/system/vertebr.service << EOF
[Unit]
Description=Vertebr System Configuration Daemon
After=network.target dbus.service bluetooth.target graphical-session.target
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

# Daemon config
Environment=VERTEBR_CONFIG=/etc/vertebr/routes.toml
Environment=VERTEBR_MODULES=/usr/lib/vertebr/modules
Environment=VERTEBR_SOCKET=/tmp/vertebr.sock

# Environnement graphique (pour xrandr, pactl, gsettings)
Environment=DISPLAY=${DISPLAY_VAL}
Environment=XAUTHORITY=${XAUTH_VAL}
Environment=DBUS_SESSION_BUS_ADDRESS=${DBUS_VAL}
Environment=PULSE_SERVER=${PULSE_SERVER_VAL}
Environment=XDG_RUNTIME_DIR=/run/user/${REAL_UID}
Environment=HOME=${REAL_HOME}

# CAPABILITIES
AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP
CapabilityBoundingSet=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP

[Install]
WantedBy=multi-user.target graphical-session.target
EOF

success "Service systemd mis à jour avec les variables d'environnement graphique"

# ── 3. Recharger et redémarrer ───────────────────────────────
info "Redémarrage du daemon..."
systemctl daemon-reload
systemctl restart vertebr
sleep 2

# ── 4. Corriger le socket immédiatement ─────────────────────
if [ -S /tmp/vertebr.sock ]; then
    chmod 777 /tmp/vertebr.sock
    success "Socket /tmp/vertebr.sock → 777"
else
    warn "Socket absent — attente..."
    sleep 3
    [ -S /tmp/vertebr.sock ] && chmod 777 /tmp/vertebr.sock
fi

# ── 5. Vérification des modules audio/display ───────────────
echo ""
info "Test des commandes système..."

# Test pactl
if PULSE_RUNTIME_PATH="/run/user/${REAL_UID}/pulse" \
   XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
   su "$REAL_USER" -c "pactl list sinks short" &>/dev/null; then
    success "pactl fonctionne (audio OK)"
else
    warn "pactl ne répond pas (PipeWire/PulseAudio non démarré ?)"
    info "Lance : systemctl --user start pipewire pipewire-pulse"
fi

# Test xrandr
if DISPLAY="$DISPLAY_VAL" XAUTHORITY="$XAUTH_VAL" \
   su "$REAL_USER" -c "xrandr --query" &>/dev/null; then
    success "xrandr fonctionne (affichage OK)"
else
    warn "xrandr ne répond pas (Wayland ? X11 ?)"
    # Détecter Wayland
    if [ -n "$(pgrep -x gnome-shell)" ]; then
        WAYLAND_VAL=$(find /run/user/"$REAL_UID" -name "wayland-*" \
            2>/dev/null | grep -v lock | head -1)
        if [ -n "$WAYLAND_VAL" ]; then
            warn "Session Wayland détectée → xrandr ne fonctionne pas nativement"
            info "Pour l'affichage sous Wayland, gnome-randr-rust ou wlr-randr est nécessaire"
        fi
    fi
fi

# Test gsettings (thème)
if DISPLAY="$DISPLAY_VAL" DBUS_SESSION_BUS_ADDRESS="$DBUS_VAL" \
   su "$REAL_USER" -c "gsettings get org.gnome.desktop.interface gtk-theme" &>/dev/null; then
    THEME=$(DISPLAY="$DISPLAY_VAL" DBUS_SESSION_BUS_ADDRESS="$DBUS_VAL" \
            su "$REAL_USER" -c "gsettings get org.gnome.desktop.interface gtk-theme" 2>/dev/null)
    success "gsettings fonctionne (thème: $THEME)"
else
    warn "gsettings ne répond pas (thème ne se chargera pas)"
fi

# ── 6. Test daemon ───────────────────────────────────────────
echo ""
info "Test de communication avec le daemon..."
if command -v socat &>/dev/null && [ -S /tmp/vertebr.sock ]; then
    RESP=$(echo '{"route":"wifi:list","payload":{}}' \
           | timeout 3 socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null | head -c 200)
    if echo "$RESP" | grep -q '"status"'; then
        success "Daemon répond correctement"
    else
        warn "Daemon ne répond pas encore"
    fi
fi

# ── 7. Résumé ────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  État :"
echo "  • Daemon      : $(systemctl is-active vertebr)"
echo "  • Socket      : $([ -S /tmp/vertebr.sock ] && stat -c 'présent (perm: %a)' /tmp/vertebr.sock || echo 'absent')"
echo "  • Modules .so : $(ls /usr/lib/vertebr/modules/*.so 2>/dev/null | wc -l) chargés"
echo ""
echo "  Relance Electron :"
echo "    cd frontend"
echo "    npx electron@28 ../electron/main.js"
echo "══════════════════════════════════════════════════════════"
echo ""
