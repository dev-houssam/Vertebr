// VERTEBR — wifi_module/entity.rs
// Modèle interne (couche domaine)

#[derive(Debug, Clone)]
pub struct WifiNetwork {
    pub ssid:             String,
    pub bssid:            String,
    pub is_connected:     bool,
    pub signal_strength:  i32,    // 0-100
    pub security:         String, // WPA2, WPA3, none...
    pub frequency:        String, // 2.4GHz, 5GHz
    pub in_use:           bool,
}

#[derive(Debug, Clone)]
pub struct WifiStatus {
    pub enabled:       bool,
    pub airplane_mode: bool,
    pub connected_to:  Option<String>,
}
