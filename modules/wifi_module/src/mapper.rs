// VERTEBR — wifi_module/mapper.rs
// Transformation Entity ↔ DTO

use crate::{entity::{WifiNetwork, WifiStatus}, dto::{NetworkDto, WifiStatusDto}};

pub struct WifiMapper;

impl WifiMapper {
    pub fn network_to_dto(e: WifiNetwork) -> NetworkDto {
        NetworkDto {
            name:      e.ssid,
            bssid:     e.bssid,
            connected: e.is_connected,
            signal:    e.signal_strength,
            secured:   e.security != "--" && !e.security.is_empty(),
            security:  e.security,
            frequency: e.frequency,
            in_use:    e.in_use,
        }
    }

    pub fn networks_to_dto(networks: Vec<WifiNetwork>) -> Vec<NetworkDto> {
        networks.into_iter().map(Self::network_to_dto).collect()
    }

    pub fn status_to_dto(s: WifiStatus) -> WifiStatusDto {
        WifiStatusDto {
            enabled:       s.enabled,
            airplane_mode: s.airplane_mode,
            connected_to:  s.connected_to,
        }
    }
}
