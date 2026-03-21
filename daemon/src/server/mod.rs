// ============================================================
// VERTEBR DAEMON — server/mod.rs
// Serveur UNIX Socket asynchrone (Tokio)
// Auteur : Houssam | Licence : MIT
// ============================================================

use std::sync::Arc;
use tokio::net::{UnixListener, UnixStream};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use serde::Deserialize;

use crate::router::Router;

pub struct ApiServer {
    router:      Arc<Router>,
    socket_path: String,
}

impl ApiServer {
    pub fn new(router: Arc<Router>, socket_path: String) -> Self {
        Self { router, socket_path }
    }

    pub async fn run(&self) -> Result<(), Box<dyn std::error::Error>> {
        // Supprimer l'ancien socket si existant
        let _ = std::fs::remove_file(&self.socket_path);

        let listener = UnixListener::bind(&self.socket_path)
            .map_err(|e| format!("Cannot bind socket {}: {}", self.socket_path, e))?;

        // Permissions du socket : 0660 (rw-rw----)
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(
                &self.socket_path,
                std::fs::Permissions::from_mode(0o660),
            )?;
        }

        println!("🟢  Vertebr API Server listening on {}", self.socket_path);
        println!("    Ready to accept connections.");
        println!();

        loop {
            match listener.accept().await {
                Ok((stream, _)) => {
                    let router = self.router.clone();
                    tokio::spawn(async move {
                        handle_connection(stream, router).await;
                    });
                }
                Err(e) => {
                    eprintln!("⚠️   Accept error: {}", e);
                }
            }
        }
    }
}

/// Gère une connexion entrante
async fn handle_connection(mut stream: UnixStream, router: Arc<Router>) {
    let caller_uid = get_peer_uid(&stream);
    let mut buffer = vec![0u8; 65536];

    loop {
        match stream.read(&mut buffer).await {
            Ok(0) => break, // Connexion fermée
            Ok(n) => {
                let raw = match std::str::from_utf8(&buffer[..n]) {
                    Ok(s) => s.trim().to_string(),
                    Err(_) => {
                        let _ = stream.write_all(
                            b"{\"status\":\"error\",\"error\":\"invalid utf8\"}\n"
                        ).await;
                        continue;
                    }
                };

                let response = process_request(&raw, &router, caller_uid);

                if let Err(e) = stream.write_all(response.as_bytes()).await {
                    eprintln!("⚠️   Write error: {}", e);
                    break;
                }
                if let Err(e) = stream.write_all(b"\n").await {
                    eprintln!("⚠️   Write error: {}", e);
                    break;
                }
            }
            Err(e) => {
                eprintln!("⚠️   Read error: {}", e);
                break;
            }
        }
    }
}

/// Parse et route une requête JSON
fn process_request(raw: &str, router: &Router, caller_uid: u32) -> String {
    // Requête spéciale : liste des routes disponibles
    if raw.trim() == "{\"route\":\"vertebr:routes\"}" {
        let routes = router.list_routes();
        return serde_json::json!({
            "status": "success",
            "data":   routes,
        }).to_string();
    }

    match serde_json::from_str::<ApiRequest>(raw) {
        Err(e) => serde_json::json!({
            "status": "error",
            "error":  format!("Invalid JSON: {}", e),
            "code":   "EPARSE"
        }).to_string(),
        Ok(req) => {
            let payload = req.payload
                .map(|p| p.to_string())
                .unwrap_or_else(|| "{}".to_string());
            router.handle(&req.route, &payload, caller_uid)
        }
    }
}

/// Récupère l'UID du processus appelant via SO_PEERCRED
fn get_peer_uid(stream: &UnixStream) -> u32 {
    #[cfg(unix)]
    {
        use std::os::unix::io::AsRawFd;
        let fd = stream.as_raw_fd();
        let mut cred = libc::ucred { pid: 0, uid: 0, gid: 0 };
        let mut len = std::mem::size_of::<libc::ucred>() as libc::socklen_t;
        unsafe {
            if libc::getsockopt(
                fd,
                libc::SOL_SOCKET,
                libc::SO_PEERCRED,
                &mut cred as *mut _ as *mut libc::c_void,
                &mut len,
            ) == 0 {
                return cred.uid;
            }
        }
    }
    // Fallback : UID inconnu → non-root
    u32::MAX
}

#[derive(Debug, Deserialize)]
struct ApiRequest {
    route:   String,
    payload: Option<serde_json::Value>,
}
