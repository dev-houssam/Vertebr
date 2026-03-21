// VERTEBR — wifi_module/lib.rs
// Point d'entrée du module : exports C ABI pour le daemon

mod entity;
mod dto;
mod mapper;
mod repository;
mod service;
pub mod controller;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Macro utilitaire pour générer les exports C de manière uniforme
macro_rules! export_handler {
    ($fn_name:ident, $handler:path) => {
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(payload_ptr: *const c_char) -> *const c_char {
            let payload = if payload_ptr.is_null() {
                "{}".to_string()
            } else {
                CStr::from_ptr(payload_ptr)
                    .to_str()
                    .unwrap_or("{}")
                    .to_string()
            };
            let response = $handler(payload);
            CString::new(response)
                .unwrap_or_else(|_| CString::new("{}").unwrap())
                .into_raw()
        }
    };
}

export_handler!(list_networks,    controller::list);
export_handler!(wifi_status,      controller::status);
export_handler!(connect_network,  controller::connect);
export_handler!(disconnect_wifi,  controller::disconnect);
export_handler!(set_wifi_enabled, controller::set_enabled);
export_handler!(airplane_mode,    controller::airplane_mode);
export_handler!(forget_network,   controller::forget);
