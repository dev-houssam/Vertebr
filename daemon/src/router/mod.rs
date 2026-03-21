// ============================================================
// VERTEBR DAEMON — router/mod.rs
// Routeur central avec chargement dynamique des modules
// Auteur : Houssam | Licence : MIT
// ============================================================

use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use libloading::{Library, Symbol};
use serde::Deserialize;

use crate::permissions::{Permission, check_permission};

/// Type des fonctions exportées par les modules (.so)
pub type HandlerFn = unsafe fn(*const c_char) -> *const c_char;

/// Représentation d'une route chargée
pub struct Route {
    pub handler:    HandlerFn,
    pub permission: Permission,
    pub _lib:       Library,   // RAII : maintient la lib en mémoire
    pub module:     String,
    pub path:       String,
}

/// Routeur principal
pub struct Router {
    routes: HashMap<String, Route>,
}

impl Router {
    /// Charge le routeur depuis routes.toml + bibliothèques dynamiques
    pub fn load_from_config(
        config_path: &str,
        modules_dir: &str,
    ) -> Result<Self, String> {
        let mut router = Self { routes: HashMap::new() };

        // Lire le fichier de configuration
        let content = std::fs::read_to_string(config_path)
            .map_err(|e| format!("Cannot read {}: {}", config_path, e))?;
        let config: RoutesConfig = toml::from_str(&content)
            .map_err(|e| format!("Cannot parse {}: {}", config_path, e))?;

        println!("📋  Loading {} routes from config...", config.route.len());

        for route_cfg in config.route {
            let module_path = format!("{}/{}", modules_dir, route_cfg.module);

            let permission = match route_cfg.permission.as_str() {
                "sudo" => Permission::Sudo,
                "caps" => Permission::Caps(route_cfg.required_caps.unwrap_or_default()),
                _      => Permission::User,
            };

            unsafe {
                match Library::new(&module_path) {
                    Err(e) => {
                        eprintln!("⚠️   Module not found: {} — {}", module_path, e);
                        continue;
                    }
                    Ok(lib) => {
                        match lib.get::<HandlerFn>(route_cfg.handler.as_bytes()) {
                            Err(e) => {
                                eprintln!("⚠️   Handler '{}' not found in {}: {}",
                                          route_cfg.handler, route_cfg.module, e);
                                continue;
                            }
                            Ok(handler) => {
                                let handler_fn = *handler;
                                router.routes.insert(route_cfg.path.clone(), Route {
                                    handler:    handler_fn,
                                    permission,
                                    _lib:       lib,
                                    module:     route_cfg.module.clone(),
                                    path:       route_cfg.path.clone(),
                                });
                                println!("  ✓  {} → {}/{}",
                                         route_cfg.path,
                                         route_cfg.module,
                                         route_cfg.handler);
                            }
                        }
                    }
                }
            }
        }

        Ok(router)
    }

    /// Traite une requête : vérifie les permissions, appelle le handler
    pub fn handle(&self, path: &str, payload: &str, caller_uid: u32) -> String {
        match self.routes.get(path) {
            None => {
                serde_json::json!({
                    "status": "error",
                    "error":  format!("Route '{}' not found", path),
                    "code":   "ENOROUTE"
                }).to_string()
            }
            Some(route) => {
                // Vérification des permissions
                if !check_permission(caller_uid, &route.permission) {
                    return serde_json::json!({
                        "status": "error",
                        "error":  "Permission denied",
                        "code":   "EPERM"
                    }).to_string();
                }

                // Appel du handler via FFI
                let payload_c = match CString::new(payload) {
                    Ok(s) => s,
                    Err(_) => return serde_json::json!({
                        "status": "error",
                        "error":  "Invalid UTF-8 in payload",
                        "code":   "EINVAL"
                    }).to_string(),
                };

                unsafe {
                    let result_ptr = (route.handler)(payload_c.as_ptr());
                    if result_ptr.is_null() {
                        return serde_json::json!({
                            "status": "error",
                            "error":  "Module returned null",
                            "code":   "ENULL"
                        }).to_string();
                    }
                    CStr::from_ptr(result_ptr)
                        .to_str()
                        .unwrap_or("{\"status\":\"error\",\"error\":\"invalid utf8\"}")
                        .to_string()
                }
            }
        }
    }

    pub fn route_count(&self) -> usize {
        self.routes.len()
    }

    pub fn list_routes(&self) -> Vec<&str> {
        self.routes.keys().map(|k| k.as_str()).collect()
    }
}

// ── Structures de désérialisation TOML ───────────────────────

#[derive(Debug, Deserialize)]
struct RoutesConfig {
    route: Vec<RouteConfig>,
}

#[derive(Debug, Deserialize)]
struct RouteConfig {
    path:          String,
    module:        String,
    handler:       String,
    permission:    String,
    required_caps: Option<Vec<String>>,
}
