#!/usr/bin/env bash
# ============================================================
# VERTEBR — fix_audio_display.sh
# Remplace et recompile audio_module + display_module
# Usage : ./fix_audio_display.sh  (SANS sudo)
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[VERTEBR]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   🦴  VERTEBR — Fix Audio + Affichage           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

[ ! -f "Cargo.toml" ] && error "Lance depuis le dossier vertebr/"

# ── 1. Ownership du dossier target ───────────────────────────
info "Correction des permissions target/..."
sudo chown -R "$(whoami):$(whoami)" target/ 2>/dev/null || true
success "OK"

# ── 2. Remplacer audio_module/src/lib.rs ─────────────────────
info "Remplacement de audio_module/src/lib.rs..."

cat > modules/audio_module/src/lib.rs << 'RUSTEOF'
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
RUSTEOF

success "audio_module/src/lib.rs remplacé"

# ── 3. Remplacer display_module/src/lib.rs ───────────────────
info "Remplacement de display_module/src/lib.rs..."

cat > modules/display_module/src/lib.rs << 'RUSTEOF'
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
RUSTEOF

success "display_module/src/lib.rs remplacé"

# ── 4. Compiler les deux modules ─────────────────────────────
info "Compilation de audio_module..."
cargo build --release -p audio_module 2>&1 | grep -E "Compiling audio|Finished|^error" | head -5
[ -f "target/release/libaudio_module.so" ] && success "audio_module OK" || { echo "FAIL"; exit 1; }

info "Compilation de display_module..."
cargo build --release -p display_module 2>&1 | grep -E "Compiling display|Finished|^error" | head -5
[ -f "target/release/libdisplay_module.so" ] && success "display_module OK" || { echo "FAIL"; exit 1; }

# ── 5. Installer ─────────────────────────────────────────────
info "Installation..."
sudo install -m755 target/release/libaudio_module.so  /usr/lib/vertebr/modules/libaudio_module.so
sudo install -m755 target/release/libdisplay_module.so /usr/lib/vertebr/modules/libdisplay_module.so
success "Modules installés"

# ── 6. DISPLAY=:1 dans le service ────────────────────────────
DISP=$(grep 'Environment=DISPLAY=' /etc/systemd/system/vertebr.service | cut -d= -f3)
if [ "$DISP" = ":0" ]; then
    sudo sed -i 's/Environment=DISPLAY=:0/Environment=DISPLAY=:1/' /etc/systemd/system/vertebr.service
    success "DISPLAY corrigé → :1"
fi

# ── 7. Redémarrer ────────────────────────────────────────────
info "Redémarrage du daemon..."
sudo systemctl daemon-reload && sudo systemctl restart vertebr
sleep 2
sudo chmod 777 /tmp/vertebr.sock
success "Daemon redémarré"

# ── 8. Tests ─────────────────────────────────────────────────
echo ""
info "Tests finaux..."

for route in "audio:sinks" "audio:sources" "display:list"; do
    RESP=$(echo "{\"route\":\"$route\",\"payload\":{}}" \
           | timeout 4 socat - UNIX-CONNECT:/tmp/vertebr.sock 2>/dev/null)
    if echo "$RESP" | grep -q '"name"'; then
        echo -e "  ${GREEN}[OK]${NC} $route ✓"
    elif echo "$RESP" | grep -q '"status":"success"'; then
        echo -e "  ${YELLOW}[WARN]${NC} $route → data vide (données système non disponibles)"
    else
        echo -e "  ${RED}[FAIL]${NC} $route → $RESP"
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅  Terminé ! Relance Electron                ║"
echo "╚══════════════════════════════════════════════════╝"
echo "  cd frontend && npx electron@28 ../electron/main.js"
echo ""
