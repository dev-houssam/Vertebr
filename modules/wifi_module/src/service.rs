// VERTEBR — wifi_module/service.rs
// Logique métier Wi-Fi

use crate::{
    repository::WifiRepository,
    mapper::WifiMapper,
    dto::{NetworkDto, WifiStatusDto},
};

pub struct WifiService;

impl WifiService {
    /// Liste les réseaux avec règles métier (tri, dédup, filtrage)
    pub fn list_networks() -> Vec<NetworkDto> {
        let mut networks = WifiRepository::scan();

        // Règle : pas de SSID vide
        networks.retain(|n| !n.ssid.trim().is_empty());

        // Règle : réseau connecté en premier, puis tri par signal
        networks.sort_by(|a, b| {
            b.in_use.cmp(&a.in_use)
                .then(b.signal_strength.cmp(&a.signal_strength))
        });

        // Règle : dédoublonnage par SSID (garde le signal le plus fort)
        let mut seen = std::collections::HashSet::new();
        networks.retain(|n| seen.insert(n.ssid.clone()));

        WifiMapper::networks_to_dto(networks)
    }

    pub fn get_status() -> WifiStatusDto {
        WifiMapper::status_to_dto(WifiRepository::get_status())
    }

    pub fn connect(ssid: &str, password: Option<&str>) -> Result<String, String> {
        if ssid.trim().is_empty() {
            return Err("SSID cannot be empty".to_string());
        }
        WifiRepository::connect(ssid, password)
    }

    pub fn disconnect() -> Result<(), String> {
        WifiRepository::disconnect("wlan0")
    }

    pub fn set_wifi_enabled(enabled: bool) -> Result<(), String> {
        WifiRepository::set_wifi_enabled(enabled)
    }

    pub fn set_airplane_mode(enabled: bool) -> Result<(), String> {
        WifiRepository::set_airplane_mode(enabled)
    }

    pub fn forget_network(ssid: &str) -> Result<(), String> {
        WifiRepository::forget_network(ssid)
    }
}
