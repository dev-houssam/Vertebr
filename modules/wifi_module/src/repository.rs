// VERTEBR — wifi_module/repository.rs
// Accès système Linux via nmcli (SEULE couche système)

use std::process::Command;
use crate::entity::{WifiNetwork, WifiStatus};

pub struct WifiRepository;

impl WifiRepository {
    /// Scanne les réseaux Wi-Fi disponibles via nmcli
    pub fn scan() -> Vec<WifiNetwork> {
        // Forcer un nouveau scan
        let _ = Command::new("nmcli")
            .args(["device", "wifi", "rescan"])
            .output();

        let output = Command::new("nmcli")
            .args([
                "-t",
                "-f", "SSID,BSSID,ACTIVE,SIGNAL,SECURITY,CHAN,FREQ,IN-USE",
                "device", "wifi", "list"
            ])
            .output();

        match output {
            Err(_) => vec![],
            Ok(out) => {
                let stdout = String::from_utf8_lossy(&out.stdout);
                stdout
                    .lines()
                    .filter(|l| !l.is_empty())
                    .map(|line| {
                        // nmcli -t sépare avec ':' et escape les ':' dans les valeurs avec '\:'
                        let parts = split_nmcli_fields(line);
                        WifiNetwork {
                            ssid:            parts.get(0).cloned().unwrap_or_default(),
                            bssid:           parts.get(1).cloned().unwrap_or_default(),
                            is_connected:    parts.get(2).map(|s| s == "yes").unwrap_or(false),
                            signal_strength: parts.get(3)
                                .and_then(|s| s.parse().ok())
                                .unwrap_or(0),
                            security:        parts.get(4).cloned().unwrap_or_else(|| "--".into()),
                            frequency:       parts.get(6).cloned().unwrap_or_default(),
                            in_use:          parts.get(7).map(|s| s == "*").unwrap_or(false),
                        }
                    })
                    .collect()
            }
        }
    }

    /// Récupère le statut Wi-Fi actuel
    pub fn get_status() -> WifiStatus {
        let radio_out = Command::new("nmcli")
            .args(["-t", "-f", "WIFI,WIFI-HW", "radio"])
            .output()
            .ok();

        let enabled = radio_out
            .as_ref()
            .map(|o| {
                let s = String::from_utf8_lossy(&o.stdout);
                s.lines()
                    .next()
                    .map(|l| l.contains("enabled"))
                    .unwrap_or(false)
            })
            .unwrap_or(false);

        let airplane_out = Command::new("nmcli")
            .args(["-t", "-f", "WIFI", "radio"])
            .output()
            .ok();

        let airplane_mode = airplane_out
            .map(|o| {
                let s = String::from_utf8_lossy(&o.stdout);
                s.contains("disabled")
            })
            .unwrap_or(false);

        // Réseau actuellement connecté
        let conn_out = Command::new("nmcli")
            .args(["-t", "-f", "DEVICE,CONNECTION", "device", "status"])
            .output()
            .ok();

        let connected_to = conn_out.and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).to_string();
            s.lines()
                .filter(|l| l.contains("wlan") || l.contains("wifi"))
                .find_map(|l| {
                    let parts: Vec<&str> = l.split(':').collect();
                    parts.get(1)
                        .filter(|c| !c.is_empty() && **c != "--")
                        .map(|c| c.to_string())
                })
        });

        WifiStatus { enabled, airplane_mode, connected_to }
    }

    /// Connecte à un réseau
    pub fn connect(ssid: &str, password: Option<&str>) -> Result<String, String> {
        let mut cmd = Command::new("nmcli");
        cmd.args(["device", "wifi", "connect", ssid]);
        if let Some(pwd) = password {
            cmd.args(["password", pwd]);
        }
        let out = cmd.output().map_err(|e| e.to_string())?;
        if out.status.success() {
            Ok(format!("Connected to {}", ssid))
        } else {
            Err(String::from_utf8_lossy(&out.stderr).to_string())
        }
    }

    /// Déconnecte du réseau actif
    pub fn disconnect(device: &str) -> Result<(), String> {
        let out = Command::new("nmcli")
            .args(["device", "disconnect", device])
            .output()
            .map_err(|e| e.to_string())?;
        if out.status.success() { Ok(()) }
        else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
    }

    /// Active/désactive le Wi-Fi
    pub fn set_wifi_enabled(enabled: bool) -> Result<(), String> {
        let state = if enabled { "on" } else { "off" };
        let out = Command::new("nmcli")
            .args(["radio", "wifi", state])
            .output()
            .map_err(|e| e.to_string())?;
        if out.status.success() { Ok(()) }
        else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
    }

    /// Active/désactive le mode avion
    pub fn set_airplane_mode(enabled: bool) -> Result<(), String> {
        let wifi_state  = if enabled { "off" } else { "on" };
        let _ = Command::new("nmcli").args(["radio", "wifi", wifi_state]).output();

        // Pour le mode avion complet, on coupe aussi la 4G/5G si disponible
        let modem_state = if enabled { "off" } else { "on" };
        let _ = Command::new("nmcli").args(["radio", "wwan", modem_state]).output();
        Ok(())
    }

    /// Oublie un réseau mémorisé
    pub fn forget_network(ssid: &str) -> Result<(), String> {
        // Chercher l'UUID de la connexion
        let out = Command::new("nmcli")
            .args(["-t", "-f", "NAME,UUID", "connection", "show"])
            .output()
            .map_err(|e| e.to_string())?;

        let stdout = String::from_utf8_lossy(&out.stdout);
        for line in stdout.lines() {
            let parts: Vec<&str> = line.splitn(2, ':').collect();
            if parts.len() == 2 && parts[0] == ssid {
                let uuid = parts[1];
                let del = Command::new("nmcli")
                    .args(["connection", "delete", uuid])
                    .output()
                    .map_err(|e| e.to_string())?;
                if del.status.success() {
                    return Ok(());
                }
            }
        }
        Err(format!("Network '{}' not found in saved connections", ssid))
    }
}

/// Sépare les champs nmcli -t en gérant les ':' échappés en '\:'
fn split_nmcli_fields(line: &str) -> Vec<String> {
    let mut fields = Vec::new();
    let mut current = String::new();
    let mut chars = line.chars().peekable();

    while let Some(c) = chars.next() {
        if c == '\\' {
            if let Some(&next) = chars.peek() {
                if next == ':' {
                    chars.next();
                    current.push(':');
                    continue;
                }
            }
            current.push(c);
        } else if c == ':' {
            fields.push(current.clone());
            current.clear();
        } else {
            current.push(c);
        }
    }
    fields.push(current);
    fields
}
