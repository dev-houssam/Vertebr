// VERTEBR — system_module/lib.rs
// Gestion système : hostname, fuseau horaire, locale, utilisateurs
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use std::fs;
use serde::{Deserialize, Serialize};
use serde_json::json;

// ── DTOs ─────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
struct SystemInfo {
    hostname:      String,
    os_name:       String,
    os_version:    String,
    kernel:        String,
    architecture:  String,
    uptime:        String,
    timezone:      String,
    locale:        String,
}

#[derive(Debug, Serialize)]
struct TimezoneInfo {
    current:    String,
    utc_offset: String,
    ntp_sync:   bool,
}

#[derive(Debug, Serialize)]
struct UserInfo {
    username: String,
    uid:      String,
    gid:      String,
    home:     String,
    shell:    String,
    groups:   Vec<String>,
}

// ── Helpers ──────────────────────────────────────────────────

fn run_cmd(cmd: &str, args: &[&str]) -> String {
    Command::new(cmd)
        .args(args)
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn run_cmd_full(cmd: &str, args: &[&str]) -> Result<String, String> {
    let out = Command::new(cmd)
        .args(args)
        .output()
        .map_err(|e| e.to_string())?;
    if out.status.success() {
        Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
    } else {
        Err(String::from_utf8_lossy(&out.stderr).trim().to_string())
    }
}

// ── Repository functions ──────────────────────────────────────

fn get_system_info() -> SystemInfo {
    // OS name & version from /etc/os-release
    let os_release = fs::read_to_string("/etc/os-release").unwrap_or_default();
    let os_name = os_release.lines()
        .find(|l| l.starts_with("PRETTY_NAME="))
        .and_then(|l| l.split('=').nth(1))
        .map(|s| s.trim_matches('"').to_string())
        .unwrap_or_else(|| "Linux".to_string());

    let os_version = os_release.lines()
        .find(|l| l.starts_with("VERSION_ID="))
        .and_then(|l| l.split('=').nth(1))
        .map(|s| s.trim_matches('"').to_string())
        .unwrap_or_default();

    // Kernel
    let kernel = run_cmd("uname", &["-r"]);

    // Architecture
    let architecture = run_cmd("uname", &["-m"]);

    // Hostname
    let hostname = run_cmd("hostname", &[]);

    // Timezone
    let timezone = run_cmd("timedatectl", &["show", "--property=Timezone", "--value"]);

    // Locale
    let locale = run_cmd("localectl", &["status"]);
    let locale_str = locale.lines()
        .find(|l| l.contains("System Locale:"))
        .and_then(|l| l.split(':').nth(1))
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "LANG=en_US.UTF-8".to_string());

    // Uptime
    let uptime_raw = run_cmd("uptime", &["-p"]);
    let uptime = uptime_raw.trim_start_matches("up ").to_string();

    SystemInfo { hostname, os_name, os_version, kernel, architecture, uptime, timezone, locale: locale_str }
}

fn get_timezone_info() -> TimezoneInfo {
    let output = run_cmd("timedatectl", &["show"]);

    let get_field = |field: &str| -> String {
        output.lines()
            .find(|l| l.starts_with(field))
            .and_then(|l| l.split('=').nth(1))
            .map(|s| s.trim().to_string())
            .unwrap_or_default()
    };

    let timezone   = get_field("Timezone");
    let ntp_sync   = get_field("NTPSynchronized") == "yes";
    let utc_offset = run_cmd("date", &["+%z"]);

    TimezoneInfo { current: timezone, utc_offset, ntp_sync }
}

fn list_timezones() -> Vec<String> {
    let output = run_cmd("timedatectl", &["list-timezones"]);
    output.lines().map(|l| l.to_string()).collect()
}

fn get_current_user() -> UserInfo {
    let username = run_cmd("whoami", &[]);
    let uid      = run_cmd("id", &["-u"]);
    let gid      = run_cmd("id", &["-g"]);
    let home     = std::env::var("HOME").unwrap_or_else(|_| format!("/home/{}", username));
    let shell    = run_cmd("getent", &["passwd", &username])
        .split(':')
        .last()
        .map(|s| s.to_string())
        .unwrap_or_else(|| "/bin/bash".to_string());

    let groups_raw = run_cmd("groups", &[]);
    let groups = groups_raw.split_whitespace().map(|s| s.to_string()).collect();

    UserInfo { username, uid, gid, home, shell, groups }
}

fn set_hostname(name: &str) -> Result<(), String> {
    if name.is_empty() || name.len() > 63 {
        return Err("Hostname must be 1-63 characters".to_string());
    }
    run_cmd_full("hostnamectl", &["set-hostname", name]).map(|_| ())
}

fn set_timezone(tz: &str) -> Result<(), String> {
    run_cmd_full("timedatectl", &["set-timezone", tz]).map(|_| ())
}

fn set_ntp(enabled: bool) -> Result<(), String> {
    let state = if enabled { "true" } else { "false" };
    run_cmd_full("timedatectl", &["set-ntp", state]).map(|_| ())
}

fn set_locale(locale: &str) -> Result<(), String> {
    run_cmd_full("localectl", &["set-locale", locale]).map(|_| ())
}

// ── Handlers ─────────────────────────────────────────────────

fn system_info(_: &str) -> String {
    json!({ "status": "success", "data": get_system_info() }).to_string()
}

fn timezone_info(_: &str) -> String {
    json!({ "status": "success", "data": get_timezone_info() }).to_string()
}

fn timezones_list(_: &str) -> String {
    let tzs = list_timezones();
    json!({ "status": "success", "data": tzs }).to_string()
}

fn current_user(_: &str) -> String {
    json!({ "status": "success", "data": get_current_user() }).to_string()
}

fn system_set_hostname(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { hostname: String }
    match serde_json::from_str::<Req>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => match set_hostname(&r.hostname) {
            Ok(_)  => json!({ "status": "success", "message": format!("Hostname set to {}", r.hostname) }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn system_set_timezone(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { timezone: String }
    match serde_json::from_str::<Req>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => match set_timezone(&r.timezone) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn system_set_ntp(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { enabled: bool }
    match serde_json::from_str::<Req>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => match set_ntp(r.enabled) {
            Ok(_)  => json!({ "status": "success" }).to_string(),
            Err(e) => json!({ "status": "error", "error": e }).to_string(),
        }
    }
}

fn system_set_locale(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { locale: String }
    match serde_json::from_str::<Req>(payload) {
        Err(e) => json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => match set_locale(&r.locale) {
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

export!(system_info_fn,         system_info);
export!(system_timezone_info,   timezone_info);
export!(system_timezones_list,  timezones_list);
export!(system_current_user,    current_user);
export!(system_set_hostname_fn, system_set_hostname);
export!(system_set_timezone_fn, system_set_timezone);
export!(system_set_ntp_fn,      system_set_ntp);
export!(system_set_locale_fn,   system_set_locale);
