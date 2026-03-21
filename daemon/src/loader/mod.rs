// ============================================================
// VERTEBR DAEMON — loader/mod.rs
// Ce module est intégré dans router/mod.rs
// Auteur : Houssam | Licence : MIT
// ============================================================

// Le chargement dynamique est géré directement dans router/mod.rs
// via libloading::Library. Ce module expose des utilitaires
// supplémentaires pour la gestion du cycle de vie des modules.

use std::path::Path;

/// Vérifie qu'un module .so est présent et lisible
pub fn module_exists(modules_dir: &str, module_name: &str) -> bool {
    let path = format!("{}/{}", modules_dir, module_name);
    Path::new(&path).exists()
}

/// Liste tous les modules disponibles dans le dossier
pub fn list_available_modules(modules_dir: &str) -> Vec<String> {
    std::fs::read_dir(modules_dir)
        .map(|entries| {
            entries
                .filter_map(|e| e.ok())
                .filter_map(|e| {
                    let name = e.file_name().to_string_lossy().to_string();
                    if name.ends_with(".so") { Some(name) } else { None }
                })
                .collect()
        })
        .unwrap_or_default()
}
