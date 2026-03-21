// VERTEBR — theme_module/lib.rs
// Gestion du thème système (GTK, GNOME, couleurs)
// Auteur : Houssam | Licence : MIT

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::process::Command;
use serde::{Deserialize, Serialize};
use serde_json::json;

// ── Entité interne ───────────────────────────────────────────

#[derive(Debug, Clone)]
struct SystemTheme {
    gtk_theme:    String,
    color_scheme: ColorScheme,
    accent_color: String,
    icon_theme:   String,
    font_name:    String,
    cursor_theme: String,
}

#[derive(Debug, Clone, PartialEq)]
enum ColorScheme {
    Dark,
    Light,
    Default,
}

impl ColorScheme {
    fn as_str(&self) -> &str {
        match self {
            Self::Dark    => "dark",
            Self::Light   => "light",
            Self::Default => "default",
        }
    }
}

// ── DTO ─────────────────────────────────────────────────────

#[derive(Serialize)]
struct ThemeDto {
    gtk_theme:    String,
    color_scheme: String,
    is_dark:      bool,
    accent_color: String,
    icon_theme:   String,
    font_name:    String,
    cursor_theme: String,
}

#[derive(Deserialize)]
struct SetThemeRequest {
    gtk_theme:    Option<String>,
    color_scheme: Option<String>,
    accent_color: Option<String>,
    icon_theme:   Option<String>,
    font_name:    Option<String>,
}

// ── Repository ──────────────────────────────────────────────

fn gsettings_get(key: &str) -> String {
    Command::new("gsettings")
        .args(["get", "org.gnome.desktop.interface", key])
        .output()
        .map(|o| {
            String::from_utf8_lossy(&o.stdout)
                .trim()
                .trim_matches('\'')
                .to_string()
        })
        .unwrap_or_default()
}

fn gsettings_set(key: &str, value: &str) -> Result<(), String> {
    let out = Command::new("gsettings")
        .args(["set", "org.gnome.desktop.interface", key, value])
        .output()
        .map_err(|e| e.to_string())?;
    if out.status.success() { Ok(()) }
    else { Err(String::from_utf8_lossy(&out.stderr).to_string()) }
}

fn detect_theme() -> SystemTheme {
    let color_scheme_raw = gsettings_get("color-scheme");
    let gtk_theme        = gsettings_get("gtk-theme");

    let color_scheme = if color_scheme_raw.contains("dark")
        || gtk_theme.to_lowercase().contains("dark")
    {
        ColorScheme::Dark
    } else if color_scheme_raw.contains("light") {
        ColorScheme::Light
    } else {
        ColorScheme::Default
    };

    SystemTheme {
        gtk_theme,
        color_scheme,
        accent_color: gsettings_get("accent-color"),
        icon_theme:   gsettings_get("icon-theme"),
        font_name:    gsettings_get("font-name"),
        cursor_theme: gsettings_get("cursor-theme"),
    }
}

fn theme_to_dto(t: &SystemTheme) -> ThemeDto {
    ThemeDto {
        gtk_theme:    t.gtk_theme.clone(),
        color_scheme: t.color_scheme.as_str().to_string(),
        is_dark:      t.color_scheme == ColorScheme::Dark,
        accent_color: t.accent_color.clone(),
        icon_theme:   t.icon_theme.clone(),
        font_name:    t.font_name.clone(),
        cursor_theme: t.cursor_theme.clone(),
    }
}

// ── Liste des thèmes GTK disponibles ────────────────────────

fn list_available_themes() -> Vec<String> {
    let mut themes = std::collections::HashSet::new();

    for dir in &[
        "/usr/share/themes",
        "/usr/local/share/themes",
        &format!("{}/.themes", std::env::var("HOME").unwrap_or_default()),
    ] {
        if let Ok(entries) = std::fs::read_dir(dir) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                // Vérifie que c'est bien un thème GTK
                let gtk_path = format!("{}/{}/gtk-3.0", dir, name);
                if std::path::Path::new(&gtk_path).exists() {
                    themes.insert(name);
                }
            }
        }
    }

    let mut sorted: Vec<String> = themes.into_iter().collect();
    sorted.sort();
    sorted
}

// ── Handlers ────────────────────────────────────────────────

fn get_theme(_payload: &str) -> String {
    let theme = detect_theme();
    let dto   = theme_to_dto(&theme);
    json!({ "status": "success", "data": dto }).to_string()
}

fn set_theme(payload: &str) -> String {
    let req: SetThemeRequest = match serde_json::from_str(payload) {
        Err(e) => return json!({ "status": "error", "error": e.to_string() }).to_string(),
        Ok(r)  => r,
    };

    let mut errors: Vec<String> = vec![];

    if let Some(ref theme) = req.gtk_theme {
        if let Err(e) = gsettings_set("gtk-theme", theme) {
            errors.push(format!("gtk-theme: {}", e));
        }
    }
    if let Some(ref scheme) = req.color_scheme {
        let val = match scheme.as_str() {
            "dark"  => "prefer-dark",
            "light" => "prefer-light",
            _       => "default",
        };
        if let Err(e) = gsettings_set("color-scheme", val) {
            errors.push(format!("color-scheme: {}", e));
        }
    }
    if let Some(ref accent) = req.accent_color {
        if let Err(e) = gsettings_set("accent-color", accent) {
            errors.push(format!("accent-color: {}", e));
        }
    }
    if let Some(ref icons) = req.icon_theme {
        if let Err(e) = gsettings_set("icon-theme", icons) {
            errors.push(format!("icon-theme: {}", e));
        }
    }
    if let Some(ref font) = req.font_name {
        if let Err(e) = gsettings_set("font-name", font) {
            errors.push(format!("font-name: {}", e));
        }
    }

    if errors.is_empty() {
        let new_theme = detect_theme();
        json!({
            "status": "success",
            "data":   theme_to_dto(&new_theme)
        }).to_string()
    } else {
        json!({ "status": "error", "errors": errors }).to_string()
    }
}

fn list_themes(_payload: &str) -> String {
    let themes = list_available_themes();
    json!({ "status": "success", "data": themes }).to_string()
}

// ── C ABI Exports ────────────────────────────────────────────

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

export!(get_system_theme, get_theme);
export!(set_system_theme, set_theme);
export!(list_gtk_themes,  list_themes);
