#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_socket_permissions.sh
# Corrige EACCES sur /tmp/vertebr.sock (une fois pour toutes)
# Usage : sudo ./fix_socket_permissions.sh
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix permissions socket      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Fix immédiat du socket ────────────────────────────────
info "Correction des permissions du socket actuel..."
if [ -S /tmp/vertebr.sock ]; then
    chmod 666 /tmp/vertebr.sock
    success "Socket /tmp/vertebr.sock → permissions 666 (rw-rw-rw-)"
else
    info "Socket absent — le daemon va le créer au démarrage"
fi

# ── 2. Patch permanent dans le service systemd ───────────────
info "Mise à jour du service systemd pour que ce soit permanent..."

cat > /etc/systemd/system/vertebr.service << 'EOF'
[Unit]
Description=Vertebr System Configuration Daemon
Documentation=https://github.com/houssam/vertebr
After=network.target dbus.service bluetooth.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/vertebr-daemon
ExecStartPost=/bin/chmod 666 /tmp/vertebr.sock
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=vertebr

Environment=VERTEBR_CONFIG=/etc/vertebr/routes.toml
Environment=VERTEBR_MODULES=/usr/lib/vertebr/modules
Environment=VERTEBR_SOCKET=/tmp/vertebr.sock

AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP
CapabilityBoundingSet=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP

[Install]
WantedBy=multi-user.target
EOF

success "Service systemd mis à jour"

# ── 3. Recharger et redémarrer ───────────────────────────────
info "Rechargement de systemd..."
systemctl daemon-reload

info "Redémarrage du daemon..."
systemctl restart vertebr
sleep 2

# ── 4. Vérifications ─────────────────────────────────────────
echo ""
if systemctl is-active --quiet vertebr; then
    success "Daemon vertebr actif"
else
    echo -e "\033[0;31m[✗]\033[0m Daemon non actif — logs :"
    journalctl -u vertebr -n 10 --no-pager
fi

if [ -S /tmp/vertebr.sock ]; then
    PERMS=$(stat -c "%a" /tmp/vertebr.sock)
    success "Socket présent — permissions : $PERMS"
    if [ "$PERMS" = "666" ]; then
        success "Permissions correctes ✓ — plus d'erreur EACCES"
    fi
else
    echo -e "\033[0;33m[⚠]\033[0m Socket absent (daemon en cours de démarrage ?)"
    sleep 2
    [ -S /tmp/vertebr.sock ] && chmod 666 /tmp/vertebr.sock && success "Socket apparu — permissions corrigées"
fi

# ── 5. Test rapide ───────────────────────────────────────────
echo ""
info "Test de communication..."
if command -v socat &>/dev/null; then
    RESP=$(echo '{"route":"wifi:status","payload":{}}' \
           | socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null | head -1)
    if [ -n "$RESP" ]; then
        success "Daemon répond : $RESP"
    else
        echo -e "\033[0;33m[⚠]\033[0m Pas de réponse (modules peut-être manquants)"
    fi
else
    info "socat non disponible — test ignoré"
fi

# ── 6. Résumé ────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  ✅  Prêt ! Relance maintenant Electron :"
echo ""
echo "    cd frontend"
echo "    npx electron@28 ../electron/main.js"
echo "══════════════════════════════════════════════════════"
echo ""
