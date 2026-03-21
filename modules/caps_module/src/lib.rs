// VERTEBR — caps_module/lib.rs
// Gestion des CAPABILITIES Linux
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Clone, Serialize)]
struct CapabilityInfo {
    name:        String,
    description: String,
    bit:         u8,
}

#[derive(Debug, Clone, Serialize)]
struct BinaryCapabilities {
    binary:       String,
    capabilities: Vec<String>,
    raw:          String,
}

#[derive(Deserialize)]
struct BinaryRequest { binary: String }

#[derive(Deserialize)]
struct GrantRequest {
    binary:       String,
    capabilities: Vec<String>,
    flags:        Option<String>,
}

#[derive(Deserialize)]
struct RevokeRequest { binary: String }

fn get_binary_caps_impl(binary: &str) -> Result<BinaryCapabilities, String> {
    if !std::path::Path::new(binary).exists() {
        return Err(format!("Binary not found: {}", binary));
    }
    let out = Command::new("getcap")
        .arg(binary)
        .output()
        .map_err(|e| format!("getcap not available: {}", e))?;
    let raw = String::from_utf8_lossy(&out.stdout).trim().to_string();
    let caps: Vec<String> = if raw.is_empty() || !raw.contains('=') {
        vec![]
    } else {
        raw.splitn(2, ' ')
            .nth(1).unwrap_or("")
            .split('=').next().unwrap_or("")
            .split(',')
            .map(|c| c.trim().to_uppercase())
            .filter(|c| !c.is_empty())
            .collect()
    };
    Ok(BinaryCapabilities { binary: binary.to_string(), capabilities: caps, raw })
}

fn grant_caps_impl(binary: &str, caps: &[String], flags: &str) -> Result<(), String> {
    if !std::path::Path::new(binary).exists() {
        return Err(format!("Binary not found: {}", binary));
    }
    if caps.is_empty() {
        return Err("No capabilities specified".to_string());
    }
    let caps_str = caps.iter().map(|c| c.to_lowercase()).collect::<Vec<_>>().join(",");
    let cap_arg = format!("{}+{}", caps_str, flags);
    let out = Command::new("setcap")
        .args([&cap_arg, binary])
        .output()
        .map_err(|e| format!("setcap not available: {}", e))?;
    if out.status.success() { Ok(()) }
    else { Err(String::from_utf8_lossy(&out.stderr).trim().to_string()) }
}

fn revoke_caps_impl(binary: &str) -> Result<(), String> {
    let out = Command::new("setcap")
        .args(["-r", binary])
        .output()
        .map_err(|e| format!("setcap not available: {}", e))?;
    if out.status.success() { Ok(()) }
    else { Err(String::from_utf8_lossy(&out.stderr).trim().to_string()) }
}

fn all_capabilities() -> Vec<CapabilityInfo> {
    vec![
        CapabilityInfo { name: "CAP_CHOWN".into(),            bit: 0,  description: "Modify file ownership".into() },
        CapabilityInfo { name: "CAP_DAC_OVERRIDE".into(),     bit: 1,  description: "Bypass file permission checks".into() },
        CapabilityInfo { name: "CAP_DAC_READ_SEARCH".into(),  bit: 2,  description: "Bypass file read permission checks".into() },
        CapabilityInfo { name: "CAP_FOWNER".into(),           bit: 3,  description: "Bypass ownership permission checks".into() },
        CapabilityInfo { name: "CAP_KILL".into(),             bit: 5,  description: "Bypass signal permission checks".into() },
        CapabilityInfo { name: "CAP_SETGID".into(),           bit: 6,  description: "Manipulate process GIDs".into() },
        CapabilityInfo { name: "CAP_SETUID".into(),           bit: 7,  description: "Manipulate process UIDs".into() },
        CapabilityInfo { name: "CAP_SETPCAP".into(),          bit: 8,  description: "Transfer and remove capabilities".into() },
        CapabilityInfo { name: "CAP_NET_BIND_SERVICE".into(), bit: 10, description: "Bind socket to privileged ports (<1024)".into() },
        CapabilityInfo { name: "CAP_NET_ADMIN".into(),        bit: 12, description: "Perform network administration operations".into() },
        CapabilityInfo { name: "CAP_NET_RAW".into(),          bit: 13, description: "Use RAW and PACKET sockets".into() },
        CapabilityInfo { name: "CAP_SYS_CHROOT".into(),       bit: 18, description: "Use chroot(2)".into() },
        CapabilityInfo { name: "CAP_SYS_PTRACE".into(),       bit: 19, description: "Trace processes using ptrace".into() },
        CapabilityInfo { name: "CAP_SYS_ADMIN".into(),        bit: 21, description: "Perform system administration operations".into() },
        CapabilityInfo { name: "CAP_SYS_BOOT".into(),         bit: 22, description: "Use reboot() and kexec_load()".into() },
        CapabilityInfo { name: "CAP_SYS_MODULE".into(),       bit: 24, description: "Load and unload kernel modules".into() },
        CapabilityInfo { name: "CAP_SYS_TIME".into(),         bit: 25, description: "Set system clock".into() },
        CapabilityInfo { name: "CAP_SETFCAP".into(),          bit: 31, description: "Set capabilities on files".into() },
    ]
}

fn handle_list(_payload: &str) -> String {
    json!({ "status": "success", "data": all_capabilities() }).to_string()
}

fn handle_get(payload: &str) -> String {
    let req: BinaryRequest = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => r,
    };
    match get_binary_caps_impl(&req.binary) {
        Ok(c)  => json!({ "status": "success", "data": c }).to_string(),
        Err(e) => json!({ "status": "error",   "error": e }).to_string(),
    }
}

fn handle_grant(payload: &str) -> String {
    let req: GrantRequest = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => r,
    };
    let flags = req.flags.as_deref().unwrap_or("ep");
    match grant_caps_impl(&req.binary, &req.capabilities, flags) {
        Ok(_)  => json!({ "status": "success", "message": format!("Capabilities granted to {}", req.binary) }).to_string(),
        Err(e) => json!({ "status": "error",   "error": e }).to_string(),
    }
}

fn handle_revoke(payload: &str) -> String {
    let req: RevokeRequest = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => r,
    };
    match revoke_caps_impl(&req.binary) {
        Ok(_)  => json!({ "status": "success", "message": format!("All capabilities revoked from {}", req.binary) }).to_string(),
        Err(e) => json!({ "status": "error",   "error": e }).to_string(),
    }
}

macro_rules! export {
    ($fn_name:ident, $handler:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(ptr: *const c_char) -> *const c_char {
            let payload = if ptr.is_null() { "{}" }
                else { CStr::from_ptr(ptr).to_str().unwrap_or("{}") };
            let response = $handler(payload);
            CString::new(response)
                .unwrap_or_else(|_| CString::new("{}").unwrap())
                .into_raw()
        }
    };
}

export!(list_capabilities,  handle_list);
export!(get_binary_caps_fn, handle_get);
export!(grant_capability,   handle_grant);
export!(revoke_capability,  handle_revoke);
