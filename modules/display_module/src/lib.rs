// VERTEBR — display_module/lib.rs
// Gestion des écrans via xrandr avec auto-détection DISPLAY
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Serialize)]
struct DisplayInfo {
    name:         String,
    connected:    bool,
    primary:      bool,
    current_mode: Option<String>,
    current_rate: Option<f32>,
    modes:        Vec<DisplayMode>,
    position:     (i32, i32),
    rotation:     String,
}

#[derive(Debug, Serialize, Clone)]
struct DisplayMode {
    resolution:    String,
    refresh_rates: Vec<f32>,
    current:       bool,
    preferred:     bool,
}

fn find_display() -> String {
    for d in &[":1", ":0", ":2"] {
        let ok = Command::new("xrandr")
            .env("DISPLAY", d).arg("--query").output()
            .map(|o| o.status.success()).unwrap_or(false);
        if ok { return d.to_string(); }
    }
    ":0".to_string()
}

fn run_xrandr(args: &[&str]) -> Result<String, String> {
    let display = std::env::var("DISPLAY").unwrap_or_else(|_| find_display());
    let mut cmd = Command::new("xrandr");
    cmd.env("DISPLAY", &display);
    if let Ok(xa) = std::env::var("XAUTHORITY") { cmd.env("XAUTHORITY", xa); }
    cmd.args(args);
    let out = cmd.output().map_err(|e| format!("xrandr not available: {}", e))?;
    if out.status.success() { Ok(String::from_utf8_lossy(&out.stdout).to_string()) }
    else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
}

fn list_displays_fn() -> Vec<DisplayInfo> {
    let output = match run_xrandr(&[]) { Ok(s) => s, Err(_) => return vec![] };
    let mut displays = Vec::new();
    let mut cur: Option<DisplayInfo> = None;

    for line in output.lines() {
        if (line.contains(" connected") || line.contains(" disconnected"))
            && !line.starts_with(' ') && !line.starts_with('\t')
        {
            if let Some(d) = cur.take() { displays.push(d); }
            let parts: Vec<&str> = line.split_whitespace().collect();
            let name      = parts.get(0).cloned().unwrap_or("").to_string();
            let connected = line.contains(" connected");
            let primary   = line.contains("primary");
            let (px, py)  = extract_pos(line);
            let rotation  = extract_rot(line);
            cur = Some(DisplayInfo { name, connected, primary, current_mode: None, current_rate: None, modes: vec![], position: (px,py), rotation });
        } else if let Some(ref mut d) = cur {
            let t = line.trim();
            if t.is_empty() { continue; }
            let parts: Vec<&str> = t.split_whitespace().collect();
            if let Some(res) = parts.first() {
                if res.contains('x') && res.chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false) {
                    let current   = t.contains('*');
                    let preferred = t.contains('+');
                    let rates: Vec<f32> = parts[1..].iter()
                        .map(|r| r.trim_matches(|c| c == '*' || c == '+'))
                        .filter_map(|r| r.parse().ok()).collect();
                    if current {
                        d.current_mode = Some(res.to_string());
                        d.current_rate = rates.first().copied();
                    }
                    d.modes.push(DisplayMode { resolution: res.to_string(), refresh_rates: rates, current, preferred });
                }
            }
        }
    }
    if let Some(d) = cur { displays.push(d); }
    displays
}

fn extract_pos(line: &str) -> (i32, i32) {
    for p in line.split_whitespace() {
        if p.contains('x') && p.contains('+') {
            let c: Vec<&str> = p.split('+').collect();
            if c.len() >= 3 { return (c[1].parse().unwrap_or(0), c[2].parse().unwrap_or(0)); }
        }
    }
    (0, 0)
}

fn extract_rot(line: &str) -> String {
    for r in &["left","right","inverted","normal"] {
        if line.split_whitespace().any(|w| w == *r) { return r.to_string(); }
    }
    "normal".to_string()
}

fn display_list(_: &str) -> String {
    json!({ "status": "success", "data": list_displays_fn() }).to_string()
}

fn display_set_mode(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { display: String, resolution: String, refresh: Option<f32> }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(), Ok(r) => r,
    };
    let display = std::env::var("DISPLAY").unwrap_or_else(|_| find_display());
    let mut cmd = Command::new("xrandr");
    cmd.env("DISPLAY", &display);
    if let Ok(xa) = std::env::var("XAUTHORITY") { cmd.env("XAUTHORITY", xa); }
    let mut args = vec!["--output".to_string(), req.display, "--mode".to_string(), req.resolution];
    if let Some(r) = req.refresh { args.extend(["--rate".to_string(), format!("{:.2}", r)]); }
    cmd.args(&args);
    let out = cmd.output().map_err(|e| e.to_string());
    match out {
        Ok(o) if o.status.success() => json!({ "status": "success" }).to_string(),
        Ok(o) => json!({ "status": "error", "error": String::from_utf8_lossy(&o.stderr).to_string() }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn display_set_rotation(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { display: String, rotation: String }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(), Ok(r) => r,
    };
    let display = std::env::var("DISPLAY").unwrap_or_else(|_| find_display());
    let mut cmd = Command::new("xrandr");
    cmd.env("DISPLAY", &display);
    if let Ok(xa) = std::env::var("XAUTHORITY") { cmd.env("XAUTHORITY", xa); }
    cmd.args(["--output", &req.display, "--rotate", &req.rotation]);
    let out = cmd.output().map_err(|e| e.to_string());
    match out {
        Ok(o) if o.status.success() => json!({ "status": "success" }).to_string(),
        Ok(o) => json!({ "status": "error", "error": String::from_utf8_lossy(&o.stderr).to_string() }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

macro_rules! export {
    ($fn_name:ident, $handler:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(ptr: *const c_char) -> *const c_char {
            let payload = if ptr.is_null() { "{}" } else { CStr::from_ptr(ptr).to_str().unwrap_or("{}") };
            let response = $handler(payload);
            CString::new(response).unwrap_or_else(|_| CString::new("{}").unwrap()).into_raw()
        }
    };
}

export!(display_list_fn,         display_list);
export!(display_set_mode_fn,     display_set_mode);
export!(display_set_rotation_fn, display_set_rotation);
