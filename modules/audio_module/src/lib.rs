// VERTEBR — audio_module/lib.rs
// Gestion Audio via vertebr-pactl (PipeWire/PulseAudio)
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Serialize)]
struct AudioSink {
    index:       u32,
    name:        String,
    description: String,
    volume:      u8,
    muted:       bool,
    is_default:  bool,
}

#[derive(Debug, Serialize)]
struct AudioSource {
    index:       u32,
    name:        String,
    description: String,
    volume:      u8,
    muted:       bool,
    is_default:  bool,
}

// Essaie vertebr-pactl puis pactl direct
fn run_pactl(args: &[&str]) -> Result<String, String> {
    let r = Command::new("vertebr-pactl").args(args).output();
    match r {
        Ok(o) if o.status.success() => return Ok(String::from_utf8_lossy(&o.stdout).to_string()),
        _ => {}
    }
    Command::new("pactl").args(args).output()
        .map_err(|e| format!("pactl not available: {}", e))
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
}

fn get_default_sink()   -> String { run_pactl(&["get-default-sink"]).unwrap_or_default().trim().to_string() }
fn get_default_source() -> String { run_pactl(&["get-default-source"]).unwrap_or_default().trim().to_string() }

fn friendly_name(name: &str) -> String {
    if name.contains("bluez")  { return "Bluetooth Audio".to_string(); }
    if name.contains("analog") { return "Built-in Audio (Analog)".to_string(); }
    if name.contains("hdmi")   { return "HDMI Audio".to_string(); }
    if name.contains("alsa")   { return "Built-in Audio".to_string(); }
    name.to_string()
}

fn extract_volume(full: &str, name: &str) -> u8 {
    let mut in_block = false;
    for line in full.lines() {
        let t = line.trim();
        if t.starts_with("Name:") { in_block = t.contains(name); }
        if in_block && t.starts_with("Volume:") && t.contains('%') {
            if let Some(pct) = t.split('%').next()
                .and_then(|s| s.rsplit('/').next())
                .and_then(|s| s.trim().parse::<u8>().ok())
            { return pct; }
        }
    }
    75
}

fn extract_muted(full: &str, name: &str) -> bool {
    let mut in_block = false;
    for line in full.lines() {
        let t = line.trim();
        if t.starts_with("Name:") { in_block = t.contains(name); }
        if in_block && t.starts_with("Mute:") { return t.contains("yes"); }
    }
    false
}

fn extract_desc(full: &str, name: &str) -> Option<String> {
    let mut in_block = false;
    for line in full.lines() {
        let t = line.trim();
        if t.starts_with("Name:") { in_block = t.contains(name); }
        if in_block && t.starts_with("Description:") {
            return Some(t.trim_start_matches("Description:").trim().to_string());
        }
    }
    None
}

fn list_sinks_fn() -> Vec<AudioSink> {
    let default  = get_default_sink();
    let short    = run_pactl(&["list", "sinks", "short"]).unwrap_or_default();
    let full     = run_pactl(&["list", "sinks"]).unwrap_or_default();

    short.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let p: Vec<&str> = line.split('\t').collect();
        if p.len() < 2 { return None; }
        let index = p[0].trim().parse::<u32>().unwrap_or(0);
        let name  = p[1].trim().to_string();
        let desc  = extract_desc(&full, &name).unwrap_or_else(|| friendly_name(&name));
        Some(AudioSink {
            index, description: desc,
            volume:     extract_volume(&full, &name),
            muted:      extract_muted(&full, &name),
            is_default: name == default || default.contains(&name),
            name,
        })
    }).collect()
}

fn list_sources_fn() -> Vec<AudioSource> {
    let default  = get_default_source();
    let short    = run_pactl(&["list", "sources", "short"]).unwrap_or_default();
    let full     = run_pactl(&["list", "sources"]).unwrap_or_default();

    short.lines()
        .filter(|l| !l.is_empty() && !l.contains("monitor"))
        .filter_map(|line| {
            let p: Vec<&str> = line.split('\t').collect();
            if p.len() < 2 { return None; }
            let index = p[0].trim().parse::<u32>().unwrap_or(0);
            let name  = p[1].trim().to_string();
            let desc  = extract_desc(&full, &name).unwrap_or_else(|| friendly_name(&name));
            Some(AudioSource {
                index, description: desc,
                volume:     extract_volume(&full, &name),
                muted:      extract_muted(&full, &name),
                is_default: name == default || default.contains(&name),
                name,
            })
        }).collect()
}

fn list_sinks(_: &str) -> String {
    json!({ "status": "success", "data": list_sinks_fn() }).to_string()
}
fn list_sources(_: &str) -> String {
    json!({ "status": "success", "data": list_sources_fn() }).to_string()
}

fn set_volume(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { sink: Option<String>, source: Option<String>, volume: u8 }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(), Ok(r) => r,
    };
    let vol  = format!("{}%", req.volume.min(100));
    let kind = if req.sink.is_some() { "sink" } else { "source" };
    let tgt  = req.sink.as_deref().or(req.source.as_deref()).unwrap_or("@DEFAULT_SINK@");
    let cmd  = format!("set-{}-volume", kind);
    match run_pactl(&[&cmd, tgt, &vol]) {
        Ok(_) => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn set_mute(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { sink: Option<String>, source: Option<String>, muted: bool }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(), Ok(r) => r,
    };
    let state = if req.muted { "1" } else { "0" };
    let kind  = if req.sink.is_some() { "sink" } else { "source" };
    let tgt   = req.sink.as_deref().or(req.source.as_deref()).unwrap_or("@DEFAULT_SINK@");
    let cmd   = format!("set-{}-mute", kind);
    match run_pactl(&[&cmd, tgt, state]) {
        Ok(_) => json!({ "status": "success" }).to_string(),
        Err(e) => json!({ "status": "error", "error": e }).to_string(),
    }
}

fn set_default_sink(payload: &str) -> String {
    #[derive(Deserialize)] struct Req { name: String }
    let req: Req = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(), Ok(r) => r,
    };
    match run_pactl(&["set-default-sink", &req.name]) {
        Ok(_) => json!({ "status": "success" }).to_string(),
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

export!(audio_list_sinks,   list_sinks);
export!(audio_list_sources, list_sources);
export!(audio_set_volume,   set_volume);
export!(audio_set_mute,     set_mute);
export!(audio_set_default,  set_default_sink);
