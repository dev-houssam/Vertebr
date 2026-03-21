// VERTEBR — wifi_module/dto.rs
// Data Transfer Objects (exposés via JSON)

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
pub struct NetworkDto {
    pub name:      String,
    pub bssid:     String,
    pub connected: bool,
    pub signal:    i32,
    pub secured:   bool,
    pub security:  String,
    pub frequency: String,
    pub in_use:    bool,
}

#[derive(Debug, Serialize)]
pub struct WifiStatusDto {
    pub enabled:       bool,
    pub airplane_mode: bool,
    pub connected_to:  Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ConnectRequest {
    pub ssid:     String,
    pub password: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AirplaneModeRequest {
    pub enabled: bool,
}
