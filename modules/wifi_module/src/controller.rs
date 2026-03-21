// VERTEBR — wifi_module/controller.rs
// Gestion des requêtes entrantes

use crate::service::WifiService;
use crate::dto::{ConnectRequest, AirplaneModeRequest};
use serde::Deserialize;
use serde_json::json;

pub fn list(_payload: String) -> String {
    let networks = WifiService::list_networks();
    json!({ "status": "success", "data": networks }).to_string()
}

pub fn status(_payload: String) -> String {
    let status = WifiService::get_status();
    json!({ "status": "success", "data": status }).to_string()
}

pub fn connect(payload: String) -> String {
    match serde_json::from_str::<ConnectRequest>(&payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(req) => match WifiService::connect(&req.ssid, req.password.as_deref()) {
            Ok(msg)  => json!({ "status": "success", "message": msg }).to_string(),
            Err(err) => json!({ "status": "error",   "error":   err }).to_string(),
        }
    }
}

pub fn disconnect(_payload: String) -> String {
    match WifiService::disconnect() {
        Ok(_)    => json!({ "status": "success", "message": "Disconnected" }).to_string(),
        Err(err) => json!({ "status": "error",   "error":   err }).to_string(),
    }
}

pub fn set_enabled(payload: String) -> String {
    #[derive(Deserialize)]
    struct Req { enabled: bool }
    match serde_json::from_str::<Req>(&payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(req) => match WifiService::set_wifi_enabled(req.enabled) {
            Ok(_)    => json!({ "status": "success" }).to_string(),
            Err(err) => json!({ "status": "error", "error": err }).to_string(),
        }
    }
}

pub fn airplane_mode(payload: String) -> String {
    match serde_json::from_str::<AirplaneModeRequest>(&payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(req) => match WifiService::set_airplane_mode(req.enabled) {
            Ok(_)    => json!({ "status": "success" }).to_string(),
            Err(err) => json!({ "status": "error", "error": err }).to_string(),
        }
    }
}

pub fn forget(payload: String) -> String {
    #[derive(Deserialize)]
    struct Req { ssid: String }
    match serde_json::from_str::<Req>(&payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(req) => match WifiService::forget_network(&req.ssid) {
            Ok(_)    => json!({ "status": "success" }).to_string(),
            Err(err) => json!({ "status": "error", "error": err }).to_string(),
        }
    }
}
