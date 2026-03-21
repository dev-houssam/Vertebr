// ============================================================
// VERTEBR DAEMON — main.rs
// Point d'entrée du daemon système
// Auteur : Houssam | Licence : MIT
// ============================================================

mod server;
mod router;
mod loader;
mod permissions;

use std::sync::Arc;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("╔═══════════════════════════════════════════╗");
    println!("║   🦴  VERTEBR DAEMON  v1.0.0              ║");
    println!("║   Architecture Modulaire — Pop!_OS        ║");
    println!("╚═══════════════════════════════════════════╝");
    println!();

    // ── Vérification des privilèges root ──────────────────
    if !is_root() {
        eprintln!("❌  Vertebr Daemon must run as root!");
        eprintln!("    Use: sudo systemctl start vertebr");
        eprintln!("    Or:  sudo vertebr-daemon");
        std::process::exit(1);
    }
    println!("✅  Running as root (UID 0)");

    // ── Chargement du routeur + modules dynamiques ────────
    let config_path  = std::env::var("VERTEBR_CONFIG")
        .unwrap_or_else(|_| "/etc/vertebr/routes.toml".to_string());
    let modules_path = std::env::var("VERTEBR_MODULES")
        .unwrap_or_else(|_| "/usr/lib/vertebr/modules".to_string());
    let socket_path  = std::env::var("VERTEBR_SOCKET")
        .unwrap_or_else(|_| "/tmp/vertebr.sock".to_string());

    println!("📁  Config  : {}", config_path);
    println!("📦  Modules : {}", modules_path);
    println!("🔌  Socket  : {}", socket_path);
    println!();

    let router = match router::Router::load_from_config(&config_path, &modules_path) {
        Ok(r) => {
            println!("✅  Router initialized — {} routes loaded", r.route_count());
            Arc::new(r)
        }
        Err(e) => {
            eprintln!("❌  Failed to initialize router: {}", e);
            std::process::exit(1);
        }
    };

    // ── Démarrage du serveur asynchrone ───────────────────
    println!();
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async {
        server::ApiServer::new(router, socket_path)
            .run()
            .await
    })?;

    Ok(())
}

fn is_root() -> bool {
    unsafe { libc::geteuid() == 0 }
}
