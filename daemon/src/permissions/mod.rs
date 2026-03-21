// ============================================================
// VERTEBR DAEMON — permissions/mod.rs
// Gestion des niveaux de permission
// Auteur : Houssam | Licence : MIT
// ============================================================

use std::fs;

/// Niveaux de permission définis dans routes.toml
#[derive(Debug, Clone)]
pub enum Permission {
    /// Tout processus connecté au socket
    User,
    /// Nécessite root ou membre du groupe sudo/wheel
    Sudo,
    /// Nécessite des CAPABILITIES Linux spécifiques
    Caps(Vec<String>),
}

/// Vérifie si un appelant (identifié par son UID) satisfait une permission
pub fn check_permission(caller_uid: u32, permission: &Permission) -> bool {
    match permission {
        Permission::User => true,

        Permission::Sudo => {
            caller_uid == 0 || is_in_sudo_group(caller_uid)
        }

        Permission::Caps(required_caps) => {
            caller_uid == 0 || has_capabilities(caller_uid, required_caps)
        }
    }
}

/// Vérifie si l'UID appartient au groupe sudo ou wheel
fn is_in_sudo_group(uid: u32) -> bool {
    let username = uid_to_username(uid);
    if username.is_empty() {
        return false;
    }

    // Lire /etc/group et chercher sudo ou wheel
    if let Ok(content) = fs::read_to_string("/etc/group") {
        for line in content.lines() {
            let parts: Vec<&str> = line.split(':').collect();
            if parts.len() >= 4 {
                let group_name = parts[0];
                let members    = parts[3];
                if (group_name == "sudo" || group_name == "wheel")
                    && members.split(',').any(|m| m.trim() == username)
                {
                    return true;
                }
            }
        }
    }
    false
}

/// Convertit un UID en nom d'utilisateur via /etc/passwd
fn uid_to_username(uid: u32) -> String {
    if let Ok(content) = fs::read_to_string("/etc/passwd") {
        for line in content.lines() {
            let parts: Vec<&str> = line.split(':').collect();
            if parts.len() >= 4 {
                if let Ok(u) = parts[2].parse::<u32>() {
                    if u == uid {
                        return parts[0].to_string();
                    }
                }
            }
        }
    }
    String::new()
}

/// Vérifie si un processus (par UID) possède les CAPABILITIES requises
/// Lit /proc/self/status (daemon) car les modules tournent dans le daemon
fn has_capabilities(uid: u32, required: &[String]) -> bool {
    // Si root, toutes les caps sont disponibles
    if uid == 0 {
        return true;
    }

    // Lire CapEff depuis /proc/self/status
    let status = match fs::read_to_string("/proc/self/status") {
        Ok(s) => s,
        Err(_) => return false,
    };

    let cap_eff = status
        .lines()
        .find(|l| l.starts_with("CapEff:"))
        .and_then(|l| l.split_whitespace().nth(1))
        .and_then(|hex| u64::from_str_radix(hex, 16).ok())
        .unwrap_or(0);

    required.iter().all(|cap| {
        if let Some(bit) = capability_bit(cap) {
            (cap_eff >> bit) & 1 == 1
        } else {
            false
        }
    })
}

/// Mapping CAPABILITY → bit dans le bitmask Linux
fn capability_bit(cap_name: &str) -> Option<u64> {
    match cap_name.to_uppercase().as_str() {
        "CAP_CHOWN"            => Some(0),
        "CAP_DAC_OVERRIDE"     => Some(1),
        "CAP_DAC_READ_SEARCH"  => Some(2),
        "CAP_FOWNER"           => Some(3),
        "CAP_FSETID"           => Some(4),
        "CAP_KILL"             => Some(5),
        "CAP_SETGID"           => Some(6),
        "CAP_SETUID"           => Some(7),
        "CAP_SETPCAP"          => Some(8),
        "CAP_NET_BIND_SERVICE" => Some(10),
        "CAP_NET_BROADCAST"    => Some(11),
        "CAP_NET_ADMIN"        => Some(12),
        "CAP_NET_RAW"          => Some(13),
        "CAP_SYS_CHROOT"       => Some(18),
        "CAP_SYS_PTRACE"       => Some(19),
        "CAP_SYS_ADMIN"        => Some(21),
        "CAP_SYS_BOOT"         => Some(22),
        "CAP_SYS_MODULE"       => Some(24),
        "CAP_SYS_TIME"         => Some(25),
        "CAP_SYS_TTY_CONFIG"   => Some(26),
        "CAP_MKNOD"            => Some(27),
        "CAP_SETFCAP"          => Some(31),
        _ => None,
    }
}
