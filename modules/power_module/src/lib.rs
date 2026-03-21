// VERTEBR — power_module/lib.rs
// Gestion de l'alimentation via upower + systemctl
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use std::fs;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Serialize)]
struct PowerStatus {
    has_battery:     bool,
    battery_percent: u8,
    battery_state:   String, // "Charging", "Discharging", "Full"
    on_battery:      bool,
    time_remaining:  Option<String>,
    power_profile:   String,
}

fn read_battery_sysfs(file: &str) -> String {
    // Try common battery paths
    for bat in &["BAT0", "BAT1", "BAT"] {
        let path = format!("/sys/class/power_supply/{}/{}", bat, file);
        if let Ok(val) = fs::read_to_string(&path) {
            return val.trim().to_string();
        }
    }
    String::new()
}

fn get_power_status() -> PowerStatus {
    let capacity_str  = read_battery_sysfs("capacity");
    let status_str    = read_battery_sysfs("status");
    let has_battery   = !capacity_str.is_empty();
    let battery_pct   = capacity_str.parse::<u8>().unwrap_or(0);
    let battery_state = if status_str.is_empty() { "Unknown".into() } else { status_str.clone() };
    let on_battery    = status_str == "Discharging";

    // Temps restant depuis upower
    let time_remaining = if has_battery {
        let out = Command::new("upower")
            .args(["-i", "/org/freedesktop/UPower/devices/battery_BAT0"])
            .output()
            .ok();
        out.and_then(|o| {
            let s = String::from_utf8_lossy(&o.stdout).to_string();
            s.lines()
                .find(|l| l.contains("time to empty") || l.contains("time to full"))
                .map(|l| l.split(':').nth(1).unwrap_or("").trim().to_string())
        })
    } else {
        None
    };

    // Profil d'alimentation (power-profiles-daemon)
    let power_profile = Command::new("powerprofilesctl")
        .arg("get")
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| "balanced".into());

    PowerStatus { has_battery, battery_percent: battery_pct, battery_state, on_battery, time_remaining, power_profile }
}

fn set_power_profile(profile: &str) -> Result<(), String> {
    let valid = ["power-saver", "balanced", "performance"];
    if !valid.contains(&profile) {
        return Err(format!("Invalid profile. Choose: {:?}", valid));
    }
    let out = Command::new("powerprofilesctl")
        .args(["set", profile])
        .output()
        .map_err(|e| format!("powerprofilesctl not available: {}", e))?;
    if out.status.success() { Ok(()) }
    else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
}

fn system_action(action: &str) -> Result<(), String> {
    let out = Command::new("systemctl")
        .arg(action)
        .output()
        .map_err(|e| e.to_string())?;
    if out.status.success() { Ok(()) }
    else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
}

// ── Handlers ─────────────────────────────────────────────────

fn power_status(_: &str) -> String {
    json!({ "status": "success", "data": get_power_status() }).to_string()
}

fn set_profile(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { profile: String }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r) => r,
    };
    match set_power_profile(&req.profile) {
        Ok(_)  => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn power_reboot(_: &str) -> String {
    match system_action("reboot") {
        Ok(_)  => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn power_shutdown(_: &str) -> String {
    match system_action("poweroff") {
        Ok(_)  => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn power_suspend(_: &str) -> String {
    match system_action("suspend") {
        Ok(_)  => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
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

export!(power_status_fn, power_status);
export!(power_set_profile, set_profile);
export!(power_reboot_fn,   power_reboot);
export!(power_shutdown_fn, power_shutdown);
export!(power_suspend_fn,  power_suspend);
