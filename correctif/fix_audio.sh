#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_audio.sh
# Corrige le Son (pactl) en faisant tourner audio_module
# avec les droits de l'utilisateur réel
# Usage : sudo ./fix_audio.sh
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix Audio (pactl)           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

[ "$EUID" -ne 0 ] && error "Lance avec sudo : sudo ./fix_audio.sh"

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
VERTEBR_DIR="$(cd "$(dirname "$0")" && pwd)"

info "Utilisateur : $REAL_USER (uid=$REAL_UID)"
info "Dossier Vertebr : $VERTEBR_DIR"

# ── 1. Créer le wrapper vertebr-pactl ───────────────────────

info "Création du wrapper /usr/local/bin/vertebr-pactl..."

cat > /usr/local/bin/vertebr-pactl << EOF
#!/bin/bash
# Wrapper pactl pour Vertebr — exécute pactl en tant que $REAL_USER
exec runuser -u $REAL_USER -- \\
    env XDG_RUNTIME_DIR=/run/user/$REAL_UID \\
        PULSE_SERVER=unix:/run/user/$REAL_UID/pulse/native \\
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_UID/bus \\
    pactl "\$@"
EOF

chmod +x /usr/local/bin/vertebr-pactl
success "Wrapper créé : /usr/local/bin/vertebr-pactl"

# Test rapide du wrapper
TEST=$(runuser -u "$REAL_USER" -- \
    env XDG_RUNTIME_DIR=/run/user/$REAL_UID \
        PULSE_SERVER=unix:/run/user/$REAL_UID/pulse/native \
    pactl list sinks short 2>/dev/null | wc -l)

if [ "$TEST" -gt 0 ]; then
    success "Wrapper fonctionne → $TEST sortie(s) audio détectée(s)"
else
    warn "pactl ne répond pas encore — PipeWire peut-être pas démarré"
fi

# ── 2. Patcher audio_module pour utiliser vertebr-pactl ─────

AUDIO_SRC="$VERTEBR_DIR/modules/audio_module/src/lib.rs"

if [ ! -f "$AUDIO_SRC" ]; then
    error "Source audio_module introuvable : $AUDIO_SRC"
fi

info "Patch de audio_module/src/lib.rs..."

# Remplacer Command::new("pactl") par Command::new("vertebr-pactl")
if grep -q '"vertebr-pactl"' "$AUDIO_SRC"; then
    success "audio_module déjà patché"
else
    sed -i 's|Command::new("pactl")|Command::new("vertebr-pactl")|g' "$AUDIO_SRC"
    PATCHED=$(grep -c '"vertebr-pactl"' "$AUDIO_SRC")
    success "$PATCHED occurrence(s) remplacée(s) dans lib.rs"
fi

# ── 3. Recompiler audio_module ───────────────────────────────

info "Recompilation de audio_module..."
cd "$VERTEBR_DIR"

cargo build --release -p audio_module 2>&1 | grep -E "Compiling|Finished|error"

if [ -f "target/release/libaudio_module.so" ]; then
    success "Compilation réussie"
else
    error "Compilation échouée — vérifier les erreurs ci-dessus"
fi

# ── 4. Installer le nouveau .so ──────────────────────────────

info "Installation de libaudio_module.so..."
install -m755 target/release/libaudio_module.so \
    /usr/lib/vertebr/modules/libaudio_module.so
success "libaudio_module.so installé dans /usr/lib/vertebr/modules/"

# ── 5. Redémarrer le daemon ──────────────────────────────────

info "Redémarrage du daemon..."
systemctl restart vertebr
sleep 2
chmod 777 /tmp/vertebr.sock 2>/dev/null
success "Daemon redémarré"

# ── 6. Test final ────────────────────────────────────────────

echo ""
info "Test de la route audio:sinks..."

if command -v socat &>/dev/null && [ -S /tmp/vertebr.sock ]; then
    RESP=$(echo '{"route":"audio:sinks","payload":{}}' \
           | timeout 4 socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null \
           | head -c 500)
    if echo "$RESP" | grep -q '"status":"success"'; then
        success "audio:sinks répond ✓"
        echo "  → $RESP" | head -c 300
    else
        warn "Réponse inattendue : $RESP"
    fi
else
    warn "socat non disponible — installe avec : sudo apt install socat"
fi

# ── 7. Résumé ────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅  fix_audio terminé                             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Relance Electron pour voir le Son :"
echo "    cd frontend"
echo "    npx electron@28 ../electron/main.js"
echo ""
