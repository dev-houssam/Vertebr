// VERTEBR — bluetooth_module/lib.rs
// Gestion Bluetooth via bluetoothctl
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use serde::{Deserialize, Serialize};
use serde_json::json;

// ── DTOs ─────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
struct BluetoothDevice {
    address:   String,
    name:      String,
    paired:    bool,
    connected: bool,
    trusted:   bool,
    device_type: String,
}

#[derive(Debug, Serialize)]
struct BluetoothStatus {
    enabled:    bool,
    discoverable: bool,
    adapter:    String,
}

#[derive(Deserialize)]
struct DeviceRequest {
    address: String,
}

// ── Repository ───────────────────────────────────────────────

fn run_bluetoothctl(args: &[&str]) -> Result<String, String> {
    let out = Command::new("bluetoothctl")
        .args(args)
        .output()
        .map_err(|e| format!("bluetoothctl not available: {}", e))?;
    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

fn get_status() -> BluetoothStatus {
    let info = run_bluetoothctl(&["show"]).unwrap_or_default();
    BluetoothStatus {
        enabled:      info.contains("Powered: yes"),
        discoverable: info.contains("Discoverable: yes"),
        adapter:      info.lines()
            .find(|l| l.contains("Name:"))
            .and_then(|l| l.split(':').nth(1))
            .map(|s| s.trim().to_string())
            .unwrap_or_else(|| "Unknown".into()),
    }
}

fn list_devices() -> Vec<BluetoothDevice> {
    let paired_out  = run_bluetoothctl(&["devices", "Paired"]).unwrap_or_default();
    let conn_out    = run_bluetoothctl(&["devices", "Connected"]).unwrap_or_default();

    let connected_addresses: Vec<&str> = conn_out
        .lines()
        .filter_map(|l| l.split_whitespace().nth(1))
        .collect();

    paired_out
        .lines()
        .filter(|l| l.starts_with("Device"))
        .map(|line| {
            let parts: Vec<&str> = line.split_whitespace().collect();
            let address = parts.get(1).cloned().unwrap_or("").to_string();
            let name    = parts[2..].join(" ");
            let info    = run_bluetoothctl(&["info", &address]).unwrap_or_default();
            BluetoothDevice {
                address:     address.clone(),
                name,
                paired:      info.contains("Paired: yes"),
                connected:   connected_addresses.contains(&address.as_str()),
                trusted:     info.contains("Trusted: yes"),
                device_type: detect_device_type(&info),
            }
        })
        .collect()
}

fn detect_device_type(info: &str) -> String {
    if info.contains("headphones") || info.contains("headset") { return "headphones".into(); }
    if info.contains("keyboard")   { return "keyboard".into(); }
    if info.contains("mouse")      { return "mouse".into(); }
    if info.contains("phone")      { return "phone".into(); }
    if info.contains("speaker")    { return "speaker".into(); }
    "device".into()
}

fn set_power(enabled: bool) -> Result<(), String> {
    let state = if enabled { "on" } else { "off" };
    run_bluetoothctl(&["power", state]).map(|_| ())
}

fn connect_device(address: &str) -> Result<(), String> {
    let out = run_bluetoothctl(&["connect", address])?;
    if out.contains("Connection successful") || out.contains("Connected") {
        Ok(())
    } else {
        Err(format!("Failed to connect to {}", address))
    }
}

fn disconnect_device(address: &str) -> Result<(), String> {
    run_bluetoothctl(&["disconnect", address]).map(|_| ())
}

fn pair_device(address: &str) -> Result<(), String> {
    run_bluetoothctl(&["pair", address]).map(|_| ())
}

fn remove_device(address: &str) -> Result<(), String> {
    run_bluetoothctl(&["remove", address]).map(|_| ())
}

// ── Handlers ─────────────────────────────────────────────────

fn bt_status(_payload: &str) -> String {
    let s = get_status();
    json!({ "status": "success", "data": s }).to_string()
}

fn bt_list(_payload: &str) -> String {
    let devices = list_devices();
    json!({ "status": "success", "data": devices }).to_string()
}

fn bt_power(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { enabled: bool }
    match serde_json::from_str::<Req>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => match set_power(r.enabled) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn bt_connect(payload: &str) -> String {
    match serde_json::from_str::<DeviceRequest>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => match connect_device(&r.address) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn bt_disconnect(payload: &str) -> String {
    match serde_json::from_str::<DeviceRequest>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => match disconnect_device(&r.address) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn bt_pair(payload: &str) -> String {
    match serde_json::from_str::<DeviceRequest>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => match pair_device(&r.address) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn bt_remove(payload: &str) -> String {
    match serde_json::from_str::<DeviceRequest>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => match remove_device(&r.address) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

// ── C ABI Exports ────────────────────────────────────────────

macro_rules! export {
    ($fn_name:ident, $handler:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(ptr: *const c_char) -> *const c_char {
            let payload = if ptr.is_null() { "{}" }
                else { CStr::from_ptr(ptr).to_str().unwrap_or("{}") };
            let response = $handler(payload);
            CString::new(response).unwrap_or_else(|_| CString::new("{}").unwrap()).into_raw()
        }
    };
}

export!(bluetooth_status,     bt_status);
export!(bluetooth_list,       bt_list);
export!(bluetooth_power,      bt_power);
export!(bluetooth_connect,    bt_connect);
export!(bluetooth_disconnect, bt_disconnect);
export!(bluetooth_pair,       bt_pair);
export!(bluetooth_remove,     bt_remove);
