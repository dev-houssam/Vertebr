# 🦴 Vertebr Module Generator

**Version :** 1.0.0  
**Auteur :** Vertebr Development Team  
**Licence :** MIT

---

## 📋 Table des matières

1. [Présentation](#présentation)
2. [Prérequis](#prérequis)
3. [Installation rapide](#installation-rapide)
4. [Guide d'utilisation](#guide-dutilisation)
5. [Comprendre la structure générée](#comprendre-la-structure-générée)
6. [Architecture technique](#architecture-technique)
7. [Personnalisation avancée](#personnalisation-avancée)
8. [Déploiement](#déploiement)
9. [Dépannage](#dépannage)
10. [FAQ](#faq)

---

## 🎯 Présentation

Le **Vertebr Module Generator** est un outil interactif en ligne de commande qui automatise la création de modules complets pour le panneau de configuration système **Vertebr**. Il génère :

- **Un backend Rust** : Bibliothèque dynamique (.so) respectant l'architecture en 7 couches inspirée de Spring Boot
- **Un frontend Vue.js** : Composants, stores, services et mappers prêts à l'emploi
- **Une archive ZIP** : Contenant l'intégralité du module prêt à compiler et déployer

### ✨ Fonctionnalités

- ✅ **Génération automatique** de l'architecture complète en 7 couches
- ✅ **Gestion des permissions** : user / sudo / CAPABILITIES Linux
- ✅ **Création interactive** des routes backend
- ✅ **Génération des exports FFI** (Foreign Function Interface) pour Rust
- ✅ **Composants Vue.js prêts à l'emploi** avec style HarmonyOS
- ✅ **Store Pinia** et **services** pré-configurés
- ✅ **Documentation automatique** (README, routes.toml)

---

## 📦 Prérequis

### Système requis
- **Linux** (Pop!_OS, Ubuntu, Debian, Fedora)
- **bash** 4.0 ou supérieur
- **zip** (pour la création de l'archive)

### Outils de développement
| Outil | Version minimale | Commande d'installation |
|-------|------------------|------------------------|
| Rust | 1.70+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Cargo | (inclus avec Rust) | - |
| Node.js | 18.x+ | `sudo apt install nodejs npm` |
| Git | 2.x+ | `sudo apt install git` |

### Vérification des prérequis
```bash
# Vérifier Rust
rustc --version
cargo --version

# Vérifier Node.js
node --version
npm --version

# Vérifier zip
zip --version
```

---

## 🚀 Installation rapide

### 1. Téléchargement du script
```bash
# Télécharger le script
curl -O https://raw.githubusercontent.com/vertebr/module-generator/main/generate_vertebr_module.sh

# Ou le créer manuellement
nano generate_vertebr_module.sh
# Coller le contenu du script, sauvegarder (Ctrl+O, Ctrl+X)
```

### 2. Rendre exécutable
```bash
chmod +x generate_vertebr_module.sh
```

### 3. Exécution
```bash
./generate_vertebr_module.sh
```

---

## 📖 Guide d'utilisation

### Exécution interactive

```bash
$ ./generate_vertebr_module.sh

╔══════════════════════════════════════════════════════════════╗
║        🦴 Générateur de module Vertebr - v1.0.0              ║
║     Créez un module complet en Rust et Vue.js en quelques secondes  ║
╚══════════════════════════════════════════════════════════════╝

▶ Informations du module
? Nom du module (ex: printer, scanner, vpn): printer
? Description du module: Gestion des imprimantes système

? Niveau de permission (1-3): 1

✓ Configuration: module=printer, permission=user

▶ Définition des routes
? Ajouter une route ? (o/n) [n]: o
? Nom de la route (ex: list, get, set): list
✓ Route ajoutée: printer:list
? Ajouter une route ? (o/n) [n]: o
? Nom de la route (ex: list, get, set): set_default
✓ Route ajoutée: printer:set_default
? Ajouter une route ? (o/n) [n]: n

▶ Génération du backend Rust
✓ Backend généré dans printer_backend/

▶ Génération du frontend Vue.js
✓ Frontend généré dans printer_frontend/

▶ Création de l'archive ZIP
✓ Archive créée: printer_module_20260321_143022.zip

▶ Nettoyage
✓ Supprimé: printer_backend/
✓ Supprimé: printer_frontend/

════════════════════════════════════════════════════════════════
✓ Module printer généré avec succès !
════════════════════════════════════════════════════════════════

📦 Archive: printer_module_20260321_143022.zip
📁 Contenu de l'archive:
   ├── printer_backend/ (backend Rust)
   ├── printer_frontend/ (frontend Vue.js)
   └── README.md (instructions)

🚀 Pour l'utiliser, décompressez l'archive et suivez le README.
```

### Options disponibles

#### 🔐 Niveaux de permission
| Niveau | Description | Cas d'usage |
|--------|-------------|-------------|
| **user** | Tout utilisateur connecté | Lecture de configuration, affichage d'infos |
| **sudo** | Nécessite droits administrateur | Modification système, installation |
| **caps** | CAPABILITIES Linux spécifiques | Configuration réseau avancée, sécurité |

#### 🎯 Routes typiques
```bash
# Pour un module "printer"
list           # Liste des imprimantes
get_status     # État d'une imprimante
set_default    # Définir imprimante par défaut
add            # Ajouter une imprimante
remove         # Supprimer une imprimante
print_test     # Imprimer une page de test
```

---

## 🏗️ Comprendre la structure générée

### Vue d'ensemble de l'archive

```
printer_module_20260321_143022.zip
│
├── printer_backend/                      # Backend Rust (daemon)
│   ├── Cargo.toml                        # Dépendances Rust
│   ├── routes.toml                       # Configuration des routes
│   └── src/
│       ├── lib.rs                        # Point d'entrée + exports C
│       ├── entity.rs                     # Modèle interne
│       ├── dto.rs                        # Data Transfer Object (API)
│       ├── mapper.rs                     # Conversion Entity ↔ DTO
│       ├── repository.rs                 # Accès système Linux
│       ├── service.rs                    # Logique métier
│       ├── controller.rs                 # Gestion des requêtes
│       └── config.rs                     # Configuration du module
│
├── printer_frontend/                     # Frontend Vue.js
│   └── src/
│       ├── views/printer/                # Vue principale
│       │   └── PrinterView.vue
│       ├── stores/printer.store.js       # Store Pinia (état)
│       ├── services/printer.service.js   # Service API
│       ├── mappers/printer.mapper.js     # Mapper DTO → Entity
│       └── routes.js                     # Configuration Vue Router
│
└── README.md                             # Documentation complète
```

---

## 🧠 Architecture technique

### Les 7 couches du backend (inspiré de Spring Boot)

```
┌─────────────────────────────────────────────────────────────┐
│                    lib.rs (Point d'entrée)                   │
│              Exports des fonctions C pour FFI                │
├─────────────────────────────────────────────────────────────┤
│                  controller.rs (Couche 1)                    │
│        Parsing JSON, validation, délégation au service       │
├─────────────────────────────────────────────────────────────┤
│                  service.rs (Couche 2)                       │
│              Logique métier, orchestration                   │
├─────────────────────────────────────────────────────────────┤
│                repository.rs (Couche 3)                      │
│          Accès système (Command::new, nmcli, etc.)           │
├─────────────────────────────────────────────────────────────┤
│                  mapper.rs (Couche 4)                        │
│            Conversion Entity ↔ DTO                          │
├─────────────────────────────────────────────────────────────┤
│            entity.rs / dto.rs (Couches 5 & 6)                │
│              Modèles de données internes/externes            │
├─────────────────────────────────────────────────────────────┤
│                  config.rs (Couche 7)                        │
│            Constantes et paramètres de configuration         │
└─────────────────────────────────────────────────────────────┘
```

### Flux de données complet

```
[Frontend Vue.js]
      │
      ▼
vertebrClient.call('printer:list', {})
      │
      ▼ (UNIX Socket)
[Daemon Rust] → Vérification permissions
      │
      ▼
[Module .so] → lib.rs → controller::list()
      │
      ▼
service::list() → mapper::to_dto_list()
      │
      ▼
repository::list() → Command::new("lpstat")
      │
      ▼
[Système Linux] → lpstat, nmcli, etc.
      │
      ▼
Retour JSON → [Frontend] → Mise à jour UI
```

### Explication détaillée des fichiers

#### 🔧 Backend Rust

| Fichier | Rôle | Code important |
|---------|------|----------------|
| **lib.rs** | Point d'entrée avec exports C | `#[no_mangle] pub extern "C" fn list_handler(...)` |
| **entity.rs** | Modèle interne | Stocke les données brutes système |
| **dto.rs** | Format API externe | Utilise `serde::Serialize` pour JSON |
| **mapper.rs** | Conversion | `to_dto()`, `to_dto_list()` |
| **repository.rs** | Accès système | `std::process::Command` |
| **service.rs** | Logique métier | Validation, orchestration |
| **controller.rs** | Gestion requêtes | `pub fn list(payload: String) -> String` |
| **routes.toml** | Configuration | Définit routes et permissions |

#### 🎨 Frontend Vue.js

| Fichier | Rôle | Code important |
|---------|------|----------------|
| **PrinterView.vue** | Composant Vue | Template, style HarmonyOS |
| **printer.store.js** | Store Pinia | État, actions, getters |
| **printer.service.js** | Service API | Appels au daemon |
| **printer.mapper.js** | Mapper | Conversion DTO → Entity |
| **routes.js** | Configuration | Définition des routes Vue |

---

## 🔧 Personnalisation avancée

### 1. Ajouter une commande système réelle

Dans `repository.rs` :

```rust
use std::process::Command;

impl PrinterRepository {
    pub fn list_printers() -> Vec<PrinterEntity> {
        let output = Command::new("lpstat")
            .args(["-t"])  // lpstat -t : toutes les infos imprimantes
            .output()
            .expect("lpstat failed - is CUPS running?");
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        
        stdout.lines()
            .filter(|line| line.contains("printer"))
            .map(|line| {
                // Parsing personnalisé selon le format de sortie
                PrinterEntity {
                    name: extract_name(line),
                    status: extract_status(line),
                    is_default: line.contains("default"),
                }
            })
            .collect()
    }
}
```

### 2. Ajouter une logique métier dans service.rs

```rust
impl PrinterService {
    pub fn set_default_printer(name: &str) -> Result<(), String> {
        // Vérification préalable
        let printers = PrinterRepository::list();
        if !printers.iter().any(|p| p.name == name) {
            return Err(format!("Imprimante '{}' inexistante", name));
        }
        
        // Vérification des droits
        if !is_admin_user() {
            return Err("Droits administrateur requis".to_string());
        }
        
        // Exécution
        PrinterRepository::set_default(name)
    }
}
```

### 3. Adapter le frontend

**Ajouter un formulaire dans PrinterView.vue** :

```vue
<template>
  <div class="printer-form">
    <input v-model="newPrinterName" placeholder="Nom de l'imprimante" />
    <input v-model="newPrinterURI" placeholder="URI (ex: ipp://192.168.1.100)" />
    <button @click="addPrinter">Ajouter</button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { printerService } from '@/services/printer.service.js'

const newPrinterName = ref('')
const newPrinterURI = ref('')

const addPrinter = async () => {
  await printerService.add(newPrinterName.value, newPrinterURI.value)
  await store.loadItems() // Rafraîchir
}
</script>
```

---

## 🚀 Déploiement

### Étape 1 : Décompresser l'archive
```bash
unzip printer_module_20260321_143022.zip
cd printer_module_20260321_143022
```

### Étape 2 : Compiler et installer le backend

```bash
# Compilation
cd printer_backend
cargo build --release

# Copier la bibliothèque
sudo cp target/release/libprinter_module.so /usr/lib/vertebr/modules/

# Ajouter les routes (fichier routes.toml fourni)
sudo tee -a /etc/vertebr/routes.toml < routes.toml

# Redémarrer le daemon
sudo systemctl restart vertebr
```

### Étape 3 : Installer le frontend

```bash
cd ../printer_frontend

# Copier les fichiers dans le projet frontend principal
cp -r src/views/printer /chemin/vers/frontend/src/views/
cp src/stores/printer.store.js /chemin/vers/frontend/src/stores/
cp src/services/printer.service.js /chemin/vers/frontend/src/services/
cp src/mappers/printer.mapper.js /chemin/vers/frontend/src/mappers/

# Ajouter la route dans router/routes.js
cat routes.js >> /chemin/vers/frontend/src/router/routes.js
```

### Étape 4 : Reconstruire l'application frontend

```bash
cd /chemin/vers/frontend
npm run build
# Si Electron : npm run make
```

### Étape 5 : Tester le module

```bash
# Vérifier que le daemon voit le module
sudo journalctl -u vertebr | grep printer

# Tester via socket direct
echo '{"route":"printer:list","payload":{}}' | nc -U /tmp/vertebr.sock
```

---

## 🐛 Dépannage

### Problème : "Cannot load module"

```bash
# Vérifier les permissions
ls -la /usr/lib/vertebr/modules/libprinter_module.so
sudo chmod 755 /usr/lib/vertebr/modules/libprinter_module.so

# Vérifier les dépendances
ldd /usr/lib/vertebr/modules/libprinter_module.so
```

### Problème : "Permission denied"

```bash
# Vérifier l'appartenance au groupe
groups $USER
sudo usermod -a -G vertebr-users $USER

# Reconnectez-vous pour appliquer
```

### Problème : Erreur de compilation Rust

```bash
# Mettre à jour Rust
rustup update

# Nettoyer et recompiler
cargo clean
cargo build --release

# Vérifier la version
rustc --version  # >= 1.70
```

### Problème : Commandes système non trouvées

```bash
# Vérifier les dépendances système
which lpstat      # Pour module imprimante
which nmcli       # Pour module Wi-Fi
which bluetoothctl # Pour module Bluetooth

# Installer si nécessaire
sudo apt install cups-client    # lpstat
sudo apt install network-manager # nmcli
```

---

## ❓ FAQ

### Q1 : Puis-je modifier le module après génération ?
**R :** Oui ! Le code généré est entièrement modifiable. Vous pouvez adapter `repository.rs` pour intégrer vos commandes système spécifiques, modifier les modèles dans `entity.rs` et `dto.rs`, et personnaliser l'interface Vue.js.

### Q2 : Comment ajouter une nouvelle route après génération ?
**R :** 
1. Ajouter la route dans `routes.toml`
2. Créer un handler dans `controller.rs`
3. Exporter la fonction dans `lib.rs`
4. Recompiler et redémarrer le daemon

### Q3 : Supporte-t-il Wayland ?
**R :** Oui, via l'architecture modulaire. Pour les fonctionnalités d'affichage, créez un module spécifique avec des appels aux API Wayland (`wlr-randr`, etc.).

### Q4 : Puis-je utiliser d'autres langages que Rust ?
**R :** Le backend doit être en Rust car le daemon utilise la FFI Rust. Cependant, vous pouvez appeler des binaires écrits en C, C++, Python, etc., via `std::process::Command`.

### Q5 : Comment déboguer un module ?
**R :**
```bash
# Voir les logs du daemon
sudo journalctl -u vertebr -f

# Activer les logs détaillés (modifier /etc/vertebr/config.toml)
log_level = "debug"

# Tester avec netcat
echo '{"route":"printer:list","payload":{}}' | nc -U /tmp/vertebr.sock | jq .
```

### Q6 : Performance des modules ?
**R :** Les modules sont chargés une seule fois au démarrage. Les appels sont directs (pas de parsing de routes à chaque fois). Les performances sont quasi-natives.

### Q7 : Sécurité des modules ?
**R :** 
- Isolation : crash d'un module n'affecte pas le daemon
- Permissions granulaires par route
- Vérification UID via SO_PEERCRED
- CAPABILITIES Linux pour le moindre privilège

### Q8 : Comment distribuer mon module ?
**R :** 
1. Générez l'archive avec le script
2. Publiez-la sur GitHub/GitLab
3. Proposez-la dans le store de modules Vertebr (à venir)

---

## 📚 Ressources additionnelles [Pas encore disponible]

- **Documentation Vertebr** : [docs.vertebr.org](https://docs.vertebr.org)
- **API Rust** : [docs.rs/vertebr-daemon](https://docs.rs/vertebr-daemon)
- **Exemples de modules** : [github.com/vertebr/modules](https://github.com/dev-houssam/Vertebr/modules)
- **Communauté** : [Discord Vertebr](https://discord.gg/vertebr)

---

## 📝 Licence

Ce générateur de module est distribué sous licence MIT. Les modules générés héritent de cette licence.

```
MIT License

Copyright (c) 2026 Vertebr Development Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Contributions

Les contributions sont les bienvenues ! 

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/amazing-feature`)
3. Commitez vos changements (`git commit -m 'Add amazing feature'`)
4. Poussez (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

---

**Créé avec ❤️ pour la communauté Vertebr**  
*Dernière mise à jour : Mars 2026*




