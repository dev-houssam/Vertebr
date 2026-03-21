#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_node_and_frontend.sh
# Règle Node.js trop vieux + installe le frontend correctement
# À lancer SANS sudo : ./fix_node_and_frontend.sh
# Auteur : Houssam | Licence : MIT
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix Node.js + Frontend      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Vérifier qu'on est au bon endroit
if [ ! -f "Cargo.toml" ] || [ ! -d "frontend" ]; then
    error "Lance ce script depuis le dossier vertebr/ (là où se trouve Cargo.toml)"
fi

# ── 1. Vérifier / installer Node.js v20 ─────────────────────

CURRENT_NODE=$(node --version 2>/dev/null || echo "none")
NODE_MAJOR=$(echo "$CURRENT_NODE" | sed 's/v//' | cut -d. -f1)

if [ "$NODE_MAJOR" -lt 18 ] 2>/dev/null || [ "$CURRENT_NODE" = "none" ]; then
    warn "Node.js $CURRENT_NODE est trop vieux (besoin de v18+). Installation de Node.js 20 LTS..."
    echo ""

    # Méthode 1 : NVM (recommandée, pas besoin de sudo pour npm)
    if command -v curl &>/dev/null; then
        info "Installation via NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

        # Charger NVM dans la session courante
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        if command -v nvm &>/dev/null; then
            nvm install 20
            nvm use 20
            nvm alias default 20
            success "Node $(node --version) installé via NVM"
        else
            warn "NVM non disponible dans ce shell. Tentative via apt..."
            # Méthode 2 : NodeSource apt repo
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            success "Node $(node --version) installé via apt"
        fi
    else
        # Méthode 2 sans curl
        sudo apt-get update -q
        sudo apt-get install -y ca-certificates gnupg
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        success "Node $(node --version) installé"
    fi
else
    success "Node.js $CURRENT_NODE OK"
fi

# Recharger NVM si installé
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

NODE_VER=$(node --version)
NPM_VER=$(npm --version)
info "Versions : Node $NODE_VER | npm $NPM_VER"

# Vérification finale
NODE_MAJOR_NEW=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR_NEW" -lt 18 ]; then
    error "Node.js $NODE_VER toujours trop vieux. Installe manuellement : https://nodejs.org"
fi

# ── 2. Nettoyer l'ancien node_modules (installé en root) ─────

info "Nettoyage de l'ancien node_modules..."
cd frontend

if [ -d "node_modules" ]; then
    # Suppression en sudo car créé par root
    sudo rm -rf node_modules
    success "node_modules supprimé"
fi

if [ -f "package-lock.json" ]; then
    rm -f package-lock.json
fi

# ── 3. Corriger package.json pour Electron sans download root ─

info "Ajustement de package.json pour Electron..."

# Créer un .npmrc pour que Electron soit téléchargé dans le home user
cat > .npmrc << 'NPMRC'
# Vertebr frontend npm config
# Electron : télécharger dans le cache user, pas /root
ELECTRON_CACHE=${HOME}/.cache/electron
ELECTRON_BUILDER_CACHE=${HOME}/.cache/electron-builder
NPMRC

success ".npmrc configuré"

# Supprimer Electron des deps pour le build (on l'utilise via npx)
# et ajuster les engines pour Node 20

# Créer un package.json simplifié sans electron dans les deps d'install
cat > package.json << 'PKGJSON'
{
  "name": "vertebr-frontend",
  "version": "1.0.0",
  "description": "Vertebr Settings UI — HarmonyOS Style for Pop!_OS",
  "author": "Houssam",
  "license": "MIT",
  "scripts": {
    "dev":   "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue":        "^3.4.0",
    "pinia":      "^2.1.0",
    "vue-router": "^4.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite":               "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
PKGJSON

success "package.json simplifié (Electron via npx)"

# ── 4. Installer les dépendances ──────────────────────────────

info "Installation des dépendances npm..."
npm install

success "Dépendances installées"

# ── 5. Builder le frontend ────────────────────────────────────

info "Build du frontend Vue.js..."
npm run build

if [ -d "dist" ]; then
    success "Frontend construit dans frontend/dist/ ✓"
else
    error "Build échoué — vérifier les erreurs ci-dessus"
fi

# ── 6. Déployer ───────────────────────────────────────────────

sudo mkdir -p /opt/vertebr/renderer
sudo cp -r dist/. /opt/vertebr/renderer/
success "Frontend déployé dans /opt/vertebr/renderer/"

cd ..

# ── 7. Installer Electron globalement pour l'utilisateur ──────

info "Installation d'Electron 28 (pour lancer l'UI)..."

# Installer dans le home user, pas en root
npm install -g electron@28 --prefer-offline 2>/dev/null || \
    npx --yes electron@28 --version > /dev/null 2>&1 || \
    warn "Electron non installé globalement — utilise npx electron@28"

# ── 8. Résumé final ───────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅  Frontend installé avec succès !                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Node.js  : $(node --version)"
echo "  Frontend : $([ -d 'frontend/dist' ] && echo 'construit ✓' || echo 'absent ✗')"
echo "  Daemon   : $(systemctl is-active vertebr 2>/dev/null || echo 'inconnu')"
echo "  Socket   : $([ -S /tmp/vertebr.sock ] && echo 'présent ✓' || echo 'absent ✗')"
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Pour lancer l'interface graphique :"
echo ""
echo "    cd frontend"
echo "    npx electron@28 ../electron/main.js"
echo ""
echo "  En mode dev (hot-reload Vue) :"
echo ""
echo "    # Terminal 1 :"
echo "    cd frontend && npm run dev"
echo "    # Terminal 2 :"
echo "    cd frontend && npx electron@28 ../electron/main.js"
echo "══════════════════════════════════════════════════════"
echo ""
