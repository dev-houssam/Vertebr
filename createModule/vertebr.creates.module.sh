#!/usr/bin/env bash

# Script : generate_vertebr_module.sh
# Description : Générateur de module pour Vertebr (Backend Rust + Frontend Vue.js)
# Auteur : Assistant
# Version : 1.0.0

set -euo pipefail
IFS=$'\n\t'

# --- Couleurs pour l'affichage ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Variables globales ---
MODULE_NAME=""
MODULE_DESC=""
MODULE_PERMISSION="user"
MODULE_CAPS=""
MODULE_ROUTES=()
BACKEND_DIR=""
FRONTEND_DIR=""
OUTPUT_ZIP=""
TEMPLATE_VERSION="1.0.0"

# --- Fonctions d'affichage ---
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        🦴 Générateur de module Vertebr - v${TEMPLATE_VERSION}          ║"
    echo "║     Créez un module complet en Rust et Vue.js en quelques secondes  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}▶${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

ask_question() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ -n "$default" ]]; then
        echo -ne "${YELLOW}?${NC} ${prompt} [${default}]: "
    else
        echo -ne "${YELLOW}?${NC} ${prompt}: "
    fi

    read -r response
    if [[ -z "$response" && -n "$default" ]]; then
        echo "$default"
    else
        echo "$response"
    fi
}

ask_confirm() {
    local prompt="$1"
    echo -ne "${YELLOW}?${NC} ${prompt} (o/n) [n]: "
    read -r response
    [[ "$response" =~ ^[Oo]$ ]]
}

# --- Fonctions de validation ---
validate_module_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
        print_error "Le nom du module doit commencer par une lettre minuscule et ne contenir que des lettres minuscules, chiffres et underscores."
        return 1
    fi
    return 0
}

# --- Collecte des informations ---
collect_info() {
    print_step "Informations du module"

    while true; do
        MODULE_NAME=$(ask_question "Nom du module (ex: printer, scanner, vpn)" "")
        if validate_module_name "$MODULE_NAME"; then
            break
        fi
    done

    MODULE_DESC=$(ask_question "Description du module" "Module ${MODULE_NAME} pour Vertebr")

    echo -e "\n${CYAN}Niveaux de permission disponibles:${NC}"
    echo "  1) user     - Tout utilisateur connecté"
    echo "  2) sudo     - Nécessite les privilèges administrateur"
    echo "  3) caps     - Nécessite des CAPABILITIES Linux spécifiques"

    local perm_choice=$(ask_question "Niveau de permission (1-3)" "1")
    case "$perm_choice" in
        2) MODULE_PERMISSION="sudo" ;;
        3)
            MODULE_PERMISSION="caps"
            MODULE_CAPS=$(ask_question "CAPABILITIES requises (ex: CAP_NET_ADMIN,CAP_SYS_ADMIN)" "CAP_NET_ADMIN")
            ;;
        *) MODULE_PERMISSION="user" ;;
    esac

    print_success "Configuration: module=${MODULE_NAME}, permission=${MODULE_PERMISSION}"

    # Routes à ajouter
    print_step "Définition des routes"
    echo "Chaque route correspond à une action du module (ex: list, connect, disconnect)"
    while ask_confirm "Ajouter une route ?"; do
        local route_name=$(ask_question "Nom de la route (ex: list, get, set)" "")
        if [[ -n "$route_name" ]]; then
            MODULE_ROUTES+=("$route_name")
            print_success "Route ajoutée: ${MODULE_NAME}:${route_name}"
        fi
    done

    if [[ ${#MODULE_ROUTES[@]} -eq 0 ]]; then
        print_warning "Aucune route définie, ajout de la route par défaut 'list'"
        MODULE_ROUTES+=("list")
    fi
}

# --- Génération du backend Rust ---
generate_backend() {
    print_step "Génération du backend Rust"

    BACKEND_DIR="${MODULE_NAME}_backend"
    mkdir -p "${BACKEND_DIR}/src"

    # Cargo.toml
    cat > "${BACKEND_DIR}/Cargo.toml" << EOF
[package]
name = "${MODULE_NAME}_module"
version = "1.0.0"
edition = "2021"
description = "${MODULE_DESC}"
authors = ["Vertebr Module Generator"]

[lib]
crate-type = ["cdylib"]

[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
libc = "0.2"
EOF

    # entity.rs
    cat > "${BACKEND_DIR}/src/entity.rs" << 'EOF'
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleEntity {
    pub id: String,
    pub name: String,
    // Ajoutez vos champs ici
}
EOF

    # dto.rs
    cat > "${BACKEND_DIR}/src/dto.rs" << EOF
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct ModuleDto {
    pub id: String,
    pub name: String,
    // Ajoutez vos champs ici
}

#[derive(Debug, serde::Deserialize)]
pub struct ModuleRequest {
    // Champs attendus dans les requêtes
}
EOF

    # mapper.rs
    cat > "${BACKEND_DIR}/src/mapper.rs" << EOF
use crate::{entity::ModuleEntity, dto::ModuleDto};

pub struct ModuleMapper;

impl ModuleMapper {
    pub fn to_dto(entity: ModuleEntity) -> ModuleDto {
        ModuleDto {
            id: entity.id,
            name: entity.name,
        }
    }

    pub fn to_dto_list(entities: Vec<ModuleEntity>) -> Vec<ModuleDto> {
        entities.into_iter().map(Self::to_dto).collect()
    }
}
EOF

    # repository.rs
    cat > "${BACKEND_DIR}/src/repository.rs" << EOF
use std::process::Command;
use crate::entity::ModuleEntity;

pub struct ModuleRepository;

impl ModuleRepository {
    /// Exemple de méthode système (à adapter)
    pub fn list() -> Vec<ModuleEntity> {
        // Remplacez par votre commande système réelle
        let output = Command::new("echo")
            .args(["list", "${MODULE_NAME}"])
            .output()
            .unwrap_or_default();

        // Parsez la sortie de la commande
        vec![
            ModuleEntity {
                id: "example_1".to_string(),
                name: "Example 1".to_string(),
            },
        ]
    }

    pub fn execute_action(action: &str, params: &str) -> Result<String, String> {
        let output = Command::new("echo")
            .args([action, params])
            .output()
            .map_err(|e| e.to_string())?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).to_string())
        } else {
            Err(String::from_utf8_lossy(&output.stderr).to_string())
        }
    }
}
EOF

    # service.rs
    cat > "${BACKEND_DIR}/src/service.rs" << EOF
use crate::{repository::ModuleRepository, mapper::ModuleMapper, dto::ModuleDto};

pub struct ModuleService;

impl ModuleService {
    pub fn list() -> Vec<ModuleDto> {
        let entities = ModuleRepository::list();
        ModuleMapper::to_dto_list(entities)
    }

    pub fn execute(action: &str, payload: &str) -> Result<String, String> {
        ModuleRepository::execute_action(action, payload)
    }
}
EOF

    # controller.rs
    cat > "${BACKEND_DIR}/src/controller.rs" << EOF
use crate::service::ModuleService;
use serde_json::json;

pub fn list(payload: String) -> String {
    let items = ModuleService::list();
    json!({
        "status": "success",
        "data": items
    }).to_string()
}

pub fn execute(payload: String) -> String {
    // Parsez le payload pour extraire action et params
    if let Ok(req) = serde_json::from_str::<serde_json::Value>(&payload) {
        let action = req.get("action").and_then(|v| v.as_str()).unwrap_or("");
        let params = req.get("params").map(|v| v.to_string()).unwrap_or_default();

        match ModuleService::execute(action, &params) {
            Ok(output) => json!({
                "status": "success",
                "data": output
            }).to_string(),
            Err(e) => json!({
                "status": "error",
                "error": e
            }).to_string(),
        }
    } else {
        json!({
            "status": "error",
            "error": "Invalid payload format"
        }).to_string()
    }
}
EOF

    # lib.rs - Point d'entrée principal
    cat > "${BACKEND_DIR}/src/lib.rs" << EOF
use std::ffi::{CStr, CString, c_char};
use std::panic;

mod entity;
mod dto;
mod mapper;
mod repository;
mod service;
mod controller;

/// Gestionnaire de panique pour éviter les crashes dans le daemon
fn handle_panic<F, R>(f: F) -> R
where
    F: FnOnce() -> R + panic::UnwindSafe,
{
    match panic::catch_unwind(f) {
        Ok(result) => result,
        Err(_) => {
            eprintln!("[${MODULE_NAME}_module] Panic caught!");
            let error_response = r#"{"status": "error", "error": "Internal module error"}"#;
            serde_json::from_str(error_response).unwrap()
        }
    }
}

/// Macro pour générer les fonctions exportées
macro_rules! export_handler {
    (\$name:ident, \$handler:expr) => {
        #[no_mangle]
        pub extern "C" fn \$name(payload_ptr: *const c_char) -> *const c_char {
            handle_panic(|| {
                let payload = unsafe {
                    CStr::from_ptr(payload_ptr)
                        .to_str()
                        .unwrap_or("{}")
                        .to_string()
                };
                let response = \$handler(payload);
                let cstring = CString::new(response).unwrap();
                cstring.into_raw()
            })
        }
    };
}

// Exportation des routes
export_handler!(list_handler, controller::list);
export_handler!(execute_handler, controller::execute);

// Ajoutez ici vos propres handlers
EOF

    # Ajout des handlers personnalisés pour chaque route
    for route in "${MODULE_ROUTES[@]}"; do
        # Convertir le nom de route en nom de fonction valide (ex: list -> list_handler)
        local handler_name="${route}_handler"
        local func_name="${route}"

        # Vérifier si le handler existe déjà dans le controller
        if ! grep -q "pub fn ${func_name}" "${BACKEND_DIR}/src/controller.rs" 2>/dev/null; then
            # Ajouter une fonction générique dans controller.rs
            cat >> "${BACKEND_DIR}/src/controller.rs" << EOF

pub fn ${func_name}(payload: String) -> String {
    // TODO: Implémentez la logique pour ${route}
    serde_json::json!({
        "status": "success",
        "message": format!("${route} action executed"),
        "payload": payload
    }).to_string()
}
EOF
        fi

        # Ajouter l'exportation dans lib.rs
        sed -i "/^\/\/ Exportation des routes/a export_handler!(${handler_name}, controller::${func_name});" "${BACKEND_DIR}/src/lib.rs"
    done

    # Routes.toml template
    cat > "${BACKEND_DIR}/routes.toml" << EOF
# Routes pour le module ${MODULE_NAME}
# Copiez ces lignes dans /etc/vertebr/routes.toml

EOF

    for route in "${MODULE_ROUTES[@]}"; do
        if [[ "$MODULE_PERMISSION" == "caps" ]]; then
            cat >> "${BACKEND_DIR}/routes.toml" << EOF
[[route]]
path = "${MODULE_NAME}:${route}"
module = "${MODULE_NAME}_module.so"
handler = "${route}_handler"
permission = "${MODULE_PERMISSION}"
required_caps = [${MODULE_CAPS}]

EOF
        else
            cat >> "${BACKEND_DIR}/routes.toml" << EOF
[[route]]
path = "${MODULE_NAME}:${route}"
module = "${MODULE_NAME}_module.so"
handler = "${route}_handler"
permission = "${MODULE_PERMISSION}"

EOF
        fi
    done

    print_success "Backend généré dans ${BACKEND_DIR}/"
}

# --- Génération du frontend Vue.js ---
generate_frontend() {
    print_step "Génération du frontend Vue.js"

    FRONTEND_DIR="${MODULE_NAME}_frontend"
    mkdir -p "${FRONTEND_DIR}/src/{views/${MODULE_NAME},stores,services,mappers}"

    # Vue principale
    local view_name="$(tr '[:lower:]' '[:upper:]' <<< ${MODULE_NAME:0:1})${MODULE_NAME:1}View"
    cat > "${FRONTEND_DIR}/src/views/${MODULE_NAME}/${view_name}.vue" << EOF
<template>
  <div class="module-container">
    <h1 class="page-title">${MODULE_DESC}</h1>

    <GlassCard>
      <div class="module-content">
        <div v-if="loading" class="loading-spinner">
          <div class="spinner"></div>
        </div>

        <div v-else-if="error" class="error-message">
          {{ error }}
        </div>

        <div v-else class="data-list">
          <div v-for="item in items" :key="item.id" class="data-item">
            <div class="item-info">
              <h3>{{ item.name }}</h3>
              <p>ID: {{ item.id }}</p>
            </div>
            <button class="action-button" @click="handleAction(item)">
              <i class="ti ti-play"></i> Action
            </button>
          </div>
        </div>

        <div v-if="items.length === 0" class="empty-state">
          <p>Aucune donnée disponible</p>
        </div>
      </div>
    </GlassCard>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { use${view_name}Store } from '@/stores/${MODULE_NAME}.store.js'
import GlassCard from '@/components/GlassCard.vue'

const store = use${view_name}Store()

const loading = store.loading
const error = store.error
const items = store.items

onMounted(() => {
  store.loadItems()
})

const handleAction = async (item) => {
  // TODO: Implémenter l'action
  console.log('Action sur:', item)
}
</script>

<style scoped>
.module-container {
  padding: 24px;
}

.page-title {
  font-size: 28px;
  font-weight: 500;
  margin-bottom: 24px;
  background: var(--accent-gradient);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.module-content {
  min-height: 400px;
}

.data-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.data-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  transition: all 0.25s ease;
}

.data-item:hover {
  background: rgba(255, 255, 255, 0.08);
  transform: translateX(4px);
}

.item-info h3 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 500;
}

.item-info p {
  margin: 0;
  font-size: 12px;
  color: var(--text-secondary);
}

.action-button {
  padding: 8px 16px;
  background: var(--accent-gradient);
  border: none;
  border-radius: 12px;
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
}

.action-button:hover {
  transform: scale(1.05);
  opacity: 0.9;
}

.loading-spinner {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border-color);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  color: #ff6b6b;
  text-align: center;
  padding: 40px;
}

.empty-state {
  text-align: center;
  padding: 60px;
  color: var(--text-secondary);
}
</style>
EOF

    # Store Pinia
    cat > "${FRONTEND_DIR}/src/stores/${MODULE_NAME}.store.js" << EOF
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ${MODULE_NAME}Service } from '@/services/${MODULE_NAME}.service.js'
import { ${MODULE_NAME}Mapper } from '@/mappers/${MODULE_NAME}.mapper.js'

export const use${view_name}Store = defineStore('${MODULE_NAME}', () => {
  const items = ref([])
  const loading = ref(false)
  const error = ref(null)

  const loadItems = async () => {
    loading.value = true
    error.value = null
    try {
      const response = await ${MODULE_NAME}Service.list()
      items.value = ${MODULE_NAME}Mapper.toEntityList(response.data)
    } catch (err) {
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  const executeAction = async (action, params = {}) => {
    loading.value = true
    try {
      const result = await ${MODULE_NAME}Service.execute(action, params)
      await loadItems() // Rafraîchir les données
      return result
    } catch (err) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    items,
    loading,
    error,
    loadItems,
    executeAction
  }
})
EOF

    # Service
    cat > "${FRONTEND_DIR}/src/services/${MODULE_NAME}.service.js" << EOF
import { vertebrClient } from '@/lib/vertebrClient'

class ${view_name}Service {
  async list() {
    const response = await vertebrClient.call('${MODULE_NAME}:list', {})
    if (response.status !== 'success') {
      throw new Error(response.error || 'Erreur lors du chargement')
    }
    return response
  }

  async execute(action, params = {}) {
    const response = await vertebrClient.call('${MODULE_NAME}:execute', {
      action,
      params
    })
    if (response.status !== 'success') {
      throw new Error(response.error || 'Erreur lors de l\'exécution')
    }
    return response
  }

  // Ajoutez ici vos méthodes spécifiques
  // async getById(id) { ... }
  // async create(data) { ... }
  // async update(id, data) { ... }
  // async delete(id) { ... }
}

export const ${MODULE_NAME}Service = new ${view_name}Service()
EOF

    # Mapper
    cat > "${FRONTEND_DIR}/src/mappers/${MODULE_NAME}.mapper.js" << EOF
// Modèle interne (Entity)
class ${view_name}Entity {
  constructor(data) {
    this.id = data.id || ''
    this.name = data.name || ''
  }

  // Méthodes calculées
  get displayName() {
    return this.name
  }
}

export const ${MODULE_NAME}Mapper = {
  toEntity(dto) {
    if (!dto) return null
    return new ${view_name}Entity({
      id: dto.id,
      name: dto.name
    })
  },

  toEntityList(dtos) {
    if (!Array.isArray(dtos)) return []
    return dtos.map(dto => this.toEntity(dto))
  },

  toDto(entity) {
    return {
      id: entity.id,
      name: entity.name
    }
  }
}
EOF

    # Route additionnelle pour le frontend
    cat > "${FRONTEND_DIR}/routes.js" << EOF
// Ajoutez ces routes dans votre router/routes.js

{
  path: '/${MODULE_NAME}',
  name: '${MODULE_NAME}',
  component: () => import('@/views/${MODULE_NAME}/${view_name}.vue'),
  meta: {
    title: '${MODULE_DESC}',
    icon: 'ti ti-puzzle',
    permission: '${MODULE_PERMISSION}',
    ${MODULE_PERMISSION == "caps" ? "requiredCaps: [" + MODULE_CAPS + "]," : ""}
    backendRoute: '${MODULE_NAME}:list'
  }
}
EOF

    print_success "Frontend généré dans ${FRONTEND_DIR}/"
}

# --- Création de l'archive ZIP ---
create_zip() {
    print_step "Création de l'archive ZIP"

    OUTPUT_ZIP="${MODULE_NAME}_module_$(date +%Y%m%d_%H%M%S).zip"

    # Créer un répertoire temporaire pour le module complet
    local temp_dir="vertebr_module_${MODULE_NAME}"
    mkdir -p "${temp_dir}"

    # Copier les répertoires
    cp -r "${BACKEND_DIR}" "${temp_dir}/"
    cp -r "${FRONTEND_DIR}" "${temp_dir}/"

    # Créer un README
    cat > "${temp_dir}/README.md" << EOF
# Module Vertebr : ${MODULE_NAME}

${MODULE_DESC}

## Structure

- \`${BACKEND_DIR}/\` - Code source Rust du daemon
- \`${FRONTEND_DIR}/\` - Code source Vue.js/Electron

## Installation

### Backend

1. Compiler le module:
   \`\`\`bash
   cd ${BACKEND_DIR}
   cargo build --release
   \`\`\`

2. Installer la bibliothèque:
   \`\`\`bash
   sudo cp target/release/lib${MODULE_NAME}_module.so /usr/lib/vertebr/modules/
   \`\`\`

3. Ajouter les routes (voir \`${BACKEND_DIR}/routes.toml\`) dans \`/etc/vertebr/routes.toml\`

4. Redémarrer le daemon:
   \`\`\`bash
   sudo systemctl restart vertebr
   \`\`\`

### Frontend

1. Copier les fichiers dans votre projet frontend:
   - \`src/views/${MODULE_NAME}/\`
   - \`src/stores/${MODULE_NAME}.store.js\`
   - \`src/services/${MODULE_NAME}.service.js\`
   - \`src/mappers/${MODULE_NAME}.mapper.js\`

2. Ajouter la route dans \`router/routes.js\` (voir \`${FRONTEND_DIR}/routes.js\`)

## Routes disponibles

| Route | Permission | Description |
|-------|------------|-------------|
EOF

    for route in "${MODULE_ROUTES[@]}"; do
        echo "| \`${MODULE_NAME}:${route}\` | \`${MODULE_PERMISSION}\` | Action ${route} |" >> "${temp_dir}/README.md"
    done

    cat >> "${temp_dir}/README.md" << EOF

## Personnalisation

- Modifier \`repository.rs\` pour intégrer les commandes système réelles
- Adapter les modèles \`entity.rs\` et \`dto.rs\` aux données métier
- Ajouter des méthodes dans le service et le controller selon les besoins

## Licence

MIT
EOF

    # Créer l'archive
    cd "$(dirname "${temp_dir}")"
    zip -r "${OUTPUT_ZIP}" "$(basename "${temp_dir}")" > /dev/null
    cd - > /dev/null

    # Nettoyer
    rm -rf "${temp_dir}"

    print_success "Archive créée: ${OUTPUT_ZIP}"
}

# --- Nettoyage des répertoires temporaires ---
cleanup() {
    print_step "Nettoyage"
    if [[ -d "${BACKEND_DIR}" ]]; then
        rm -rf "${BACKEND_DIR}"
        print_success "Supprimé: ${BACKEND_DIR}"
    fi
    if [[ -d "${FRONTEND_DIR}" ]]; then
        rm -rf "${FRONTEND_DIR}"
        print_success "Supprimé: ${FRONTEND_DIR}"
    fi
}

# --- Fonction principale ---
main() {
    print_header

    collect_info

    generate_backend
    generate_frontend
    create_zip

    cleanup

    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
    print_success "Module ${MODULE_NAME} généré avec succès !"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "\n📦 Archive: ${CYAN}${OUTPUT_ZIP}${NC}"
    echo -e "\n📁 Contenu de l'archive:"
    echo -e "   ├── ${BACKEND_DIR}/ (backend Rust)"
    echo -e "   ├── ${FRONTEND_DIR}/ (frontend Vue.js)"
    echo -e "   └── README.md (instructions)"
    echo -e "\n🚀 Pour l'utiliser, décompressez l'archive et suivez le README."
    echo -e "\n${YELLOW}Note:${NC} Adaptez le code du repository pour utiliser les vraies commandes système !"
}

# --- Exécution ---
main "$@"