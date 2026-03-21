#!/usr/bin/env bash
# ============================================================
# VERTEBR — install.sh v2.0
# Script d'installation complet pour Pop!_OS / Ubuntu
# Intègre tous les correctifs : socket, DBUS, audio, affichage
# Auteur : Houssam | Licence : MIT
# Usage : sudo ./install.sh
# ============================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ██╗   ██╗███████╗██████╗ ████████╗███████╗██████╗ ██████╗ "
echo "  ██║   ██║██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗"
echo "  ██║   ██║█████╗  ██████╔╝   ██║   █████╗  ██████╔╝██████╔╝"
echo "  ╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║   ██╔══╝  ██╔══██╗██╔══██╗"
echo "   ╚████╔╝ ███████╗██║  ██║   ██║   ███████╗██████╔╝██║  ██║"
echo "    ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "  ${BOLD}Installateur v2.0 — Pop!_OS / Ubuntu${NC}"
echo -e "  Auteur : Houssam | Licence : MIT"
echo ""

# ── Vérifications préalables ─────────────────────────────────

[ "$EUID" -ne 0 ] && error "Ce script doit être exécuté en root : sudo ./install.sh"
! command -v cargo &>/dev/null && error "Rust/Cargo non trouvé.\n  Installe : curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
! command -v node  &>/dev/null && error "Node.js non trouvé.\n  Installe : sudo apt install nodejs npm"

NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ] 2>/dev/null; then
    warn "Node.js $(node --version) trop vieux (besoin v18+)"
    warn "Lance d'abord : curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install nodejs"
    error "Node.js >= 18 requis pour le frontend"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

info "Répertoire : $SCRIPT_DIR"
info "Utilisateur : $REAL_USER (uid=$REAL_UID)"
echo ""

# ── Étape 1 : Détection de l'environnement graphique ─────────
step "1/10 Détection de l'environnement graphique"

# DISPLAY : chercher dans les processus actifs
DISPLAY_VAL=""
for d in ":1" ":0" ":2"; do
    if runuser -u "$REAL_USER" -- env DISPLAY="$d" xrandr --query &>/dev/null 2>&1; then
        DISPLAY_VAL="$d"
        break
    fi
done
DISPLAY_VAL="${DISPLAY_VAL:-:1}"

# XAUTHORITY
XAUTH_VAL="/run/user/${REAL_UID}/gdm/Xauthority"
[ ! -f "$XAUTH_VAL" ] && XAUTH_VAL="$REAL_HOME/.Xauthority"

# DBUS : chercher dans /proc des processus user
DBUS_VAL=$(
    for pid in $(ps -u "$REAL_UID" -o pid= 2>/dev/null); do
        cat /proc/"$pid"/environ 2>/dev/null
    done \
    | tr '\0' '\n' \
    | grep '^DBUS_SESSION_BUS_ADDRESS=' \
    | head -1 | cut -d= -f2-
)
DBUS_VAL="${DBUS_VAL:-unix:path=/run/user/${REAL_UID}/bus}"

# PULSE
PULSE_VAL="unix:/run/user/${REAL_UID}/pulse/native"
[ ! -S "/run/user/${REAL_UID}/pulse/native" ] && PULSE_VAL=""

info "DISPLAY      = $DISPLAY_VAL"
info "XAUTHORITY   = $XAUTH_VAL"
info "DBUS         = $DBUS_VAL"
info "PULSE_SERVER = ${PULSE_VAL:-(détection auto)}"
success "Environnement graphique détecté"

# ── Étape 2 : Reprendre ownership du dossier target ──────────
step "2/10 Préparation du workspace Rust"

if [ -d "$SCRIPT_DIR/target" ]; then
    chown -R "$REAL_USER:$REAL_USER" "$SCRIPT_DIR/target" 2>/dev/null || true
fi
success "Permissions workspace OK"

# ── Étape 3 : Compilation du daemon ──────────────────────────
step "3/10 Compilation du daemon Rust"

cd "$SCRIPT_DIR"
# Compiler en tant qu'utilisateur normal pour éviter les problèmes de permissions
runuser -u "$REAL_USER" -- cargo build --release -p vertebr-daemon 2>&1 \
    | grep -E "Compiling vertebr|Finished|^error" | tail -5
success "Daemon compilé"

# ── Étape 4 : Compilation des modules ────────────────────────
step "4/10 Compilation des modules (.so)"

MODULES=(wifi_module bluetooth_module caps_module theme_module
         audio_module display_module power_module system_module)

for module in "${MODULES[@]}"; do
    info "  → $module..."
    runuser -u "$REAL_USER" -- cargo build --release -p "$module" 2>&1 \
        | grep -E "Compiling $module|Finished|^error" | tail -2
    if [ -f "target/release/lib${module}.so" ]; then
        success "  $module compilé"
    else
        warn "  $module : compilation échouée ou ignorée"
    fi
done

# ── Étape 5 : Création du wrapper vertebr-pactl ──────────────
step "5/10 Création du wrapper audio (vertebr-pactl)"

cat > /usr/local/bin/vertebr-pactl << WRAPEOF
#!/bin/bash
# Wrapper pactl pour Vertebr — exécute pactl en tant que $REAL_USER
exec runuser -u $REAL_USER -- \\
    env XDG_RUNTIME_DIR=/run/user/$REAL_UID \\
        PULSE_SERVER=${PULSE_VAL:-unix:/run/user/$REAL_UID/pulse/native} \\
        DBUS_SESSION_BUS_ADDRESS=$DBUS_VAL \\
    pactl "\$@"
WRAPEOF

chmod +x /usr/local/bin/vertebr-pactl
success "Wrapper /usr/local/bin/vertebr-pactl créé"

# ── Étape 6 : Installation du daemon et des modules ──────────
step "6/10 Installation des binaires"

install -m 755 target/release/vertebr-daemon /usr/bin/vertebr-daemon
success "vertebr-daemon → /usr/bin/"

mkdir -p /usr/lib/vertebr/modules
for module in "${MODULES[@]}"; do
    src="target/release/lib${module}.so"
    dst="/usr/lib/vertebr/modules/lib${module}.so"
    if [ -f "$src" ]; then
        install -m 755 "$src" "$dst"
        success "  $(basename $src) → $dst"
    else
        warn "  $src introuvable (ignoré)"
    fi
done

# ── Étape 7 : Configuration ───────────────────────────────────
step "7/10 Configuration"

mkdir -p /etc/vertebr
install -m 644 config/routes.toml /etc/vertebr/routes.toml
ROUTE_COUNT=$(grep -c '^\[\[route\]\]' /etc/vertebr/routes.toml 2>/dev/null || echo 0)
success "routes.toml installé ($ROUTE_COUNT routes)"

# ── Étape 8 : Groupe système et service systemd ───────────────
step "8/10 Service systemd"

# Groupe vertebr-users
if ! getent group vertebr-users &>/dev/null; then
    groupadd vertebr-users
    success "Groupe vertebr-users créé"
fi
usermod -aG vertebr-users "$REAL_USER" 2>/dev/null || true
success "Utilisateur $REAL_USER → groupe vertebr-users"

# Écrire le service avec toutes les variables d'environnement
cat > /etc/systemd/system/vertebr.service << SVCEOF
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

# ── Daemon ────────────────────────────────────
Environment=VERTEBR_CONFIG=/etc/vertebr/routes.toml
Environment=VERTEBR_MODULES=/usr/lib/vertebr/modules
Environment=VERTEBR_SOCKET=/tmp/vertebr.sock

# ── Environnement graphique ───────────────────
Environment=DISPLAY=${DISPLAY_VAL}
Environment=XAUTHORITY=${XAUTH_VAL}
Environment=DBUS_SESSION_BUS_ADDRESS=${DBUS_VAL}
Environment=PULSE_SERVER=${PULSE_VAL:-unix:/run/user/${REAL_UID}/pulse/native}
Environment=XDG_RUNTIME_DIR=/run/user/${REAL_UID}
Environment=HOME=${REAL_HOME}

# ── CAPABILITIES ─────────────────────────────
AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP
CapabilityBoundingSet=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable vertebr.service
systemctl restart vertebr.service
sleep 2

if systemctl is-active --quiet vertebr.service; then
    success "Service vertebr actif"
else
    warn "Service non démarré — consulte : journalctl -u vertebr -n 20"
fi

# S'assurer que le socket est accessible
if [ -S /tmp/vertebr.sock ]; then
    chmod 777 /tmp/vertebr.sock
    success "Socket /tmp/vertebr.sock accessible (777)"
else
    warn "Socket absent — démarrage peut prendre quelques secondes"
fi

# ── Étape 9 : Frontend Vue.js ─────────────────────────────────
step "9/10 Frontend Vue.js"

if [ -d "$SCRIPT_DIR/frontend" ]; then
    cd "$SCRIPT_DIR/frontend"

    info "Installation des dépendances npm..."
    # Installer en tant qu'utilisateur normal
    runuser -u "$REAL_USER" -- npm install --legacy-peer-deps 2>&1 \
        | grep -v "WARN\|npm notice" | tail -5

    info "Build du frontend..."
    runuser -u "$REAL_USER" -- npm run build 2>&1 | tail -5

    if [ -d "dist" ]; then
        mkdir -p /opt/vertebr/renderer
        cp -r dist/. /opt/vertebr/renderer/
        success "Frontend déployé dans /opt/vertebr/renderer/"
    else
        warn "Build frontend échoué — lance manuellement : cd frontend && npm run build"
    fi

    cd "$SCRIPT_DIR"
else
    warn "Dossier frontend/ absent"
fi

# ── Étape 10 : Vérification finale ───────────────────────────
step "10/10 Vérification"

# Tester le daemon
if command -v socat &>/dev/null && [ -S /tmp/vertebr.sock ]; then
    RESP=$(echo '{"route":"wifi:status","payload":{}}' \
           | timeout 4 socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null)
    if echo "$RESP" | grep -q '"status":"success"'; then
        success "Daemon répond correctement ✓"
    else
        warn "Daemon ne répond pas encore (normal au démarrage)"
    fi
fi

# ── Résumé ────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅  VERTEBR installé avec succès !                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Daemon   : /usr/bin/vertebr-daemon"
echo "  Modules  : /usr/lib/vertebr/modules/ ($(ls /usr/lib/vertebr/modules/*.so 2>/dev/null | wc -l) modules)"
echo "  Config   : /etc/vertebr/routes.toml ($ROUTE_COUNT routes)"
echo "  Socket   : /tmp/vertebr.sock"
echo "  Frontend : /opt/vertebr/renderer/"
echo ""
echo "  Pour lancer l'interface :"
echo -e "    ${CYAN}cd frontend && npx electron@28 ../electron/main.js${NC}"
echo ""
echo "  Commandes utiles :"
echo "    systemctl status vertebr          # État du daemon"
echo "    journalctl -u vertebr -f          # Logs en direct"
echo "    sudo chmod 777 /tmp/vertebr.sock  # Si EACCES"
echo ""
echo -e "${YELLOW}⚠  Déconnecte-toi et reconnecte-toi pour appliquer le groupe vertebr-users${NC}"
echo ""
