use tauri::{AppHandle, LogicalPosition, LogicalSize, Manager};

use crate::native::macos::configure_edge_deck_panel;

#[tauri::command]
pub fn setup_edge_deck(app: AppHandle) -> Result<(), String> {
    set_window_mode(app, "deck".to_string())
}

#[tauri::command]
pub fn set_window_mode(app: AppHandle, mode: String) -> Result<(), String> {
    if let Some(window) = app.get_webview_window("deck") {
        #[cfg(target_os = "macos")]
        {
            if let Ok(ptr) = window.ns_window() {
                unsafe {
                    configure_edge_deck_panel(ptr);
                }
            }
        }

        let monitor = window
            .current_monitor()
            .ok()
            .flatten()
            .or_else(|| window.primary_monitor().ok().flatten());

        if let Some(mon) = monitor {
            let scale_factor = mon.scale_factor();
            let screen_size = mon.size().to_logical::<f64>(scale_factor);
            let screen_pos = mon.position().to_logical::<f64>(scale_factor);

            let screen_w = screen_size.width;
            let screen_h = screen_size.height;
            let screen_x = screen_pos.x;
            let screen_y = screen_pos.y;

            let (target_w, target_h, target_x, target_y) = match mode.as_str() {
                "onboarding" => {
                    let w = 760.0;
                    let h = 480.0;
                    let x = screen_x + (screen_w - w) / 2.0;
                    let y = screen_y + (screen_h - h) / 2.0;
                    (w, h, x, y)
                }
                "archive" => {
                    let w = 640.0;
                    let h = 460.0;
                    let x = screen_x + (screen_w - w) / 2.0;
                    let y = screen_y + (screen_h - h) / 2.0;
                    (w, h, x, y)
                }
                "editor" => {
                    let w = screen_w;
                    let h = screen_h;
                    let x = screen_x;
                    let y = screen_y;
                    (w, h, x, y)
                }
                "deck_hover" => {
                    let w = 240.0;
                    let h = screen_h * 0.85;
                    let x = screen_x + screen_w - w;
                    let y = screen_y + (screen_h - h) / 2.0;
                    (w, h, x, y)
                }
                _ => {
                    let w = 48.0;
                    let h = screen_h * 0.85;
                    let x = screen_x + screen_w - w;
                    let y = screen_y + (screen_h - h) / 2.0;
                    (w, h, x, y)
                }
            };

            let _ = window.set_size(LogicalSize::new(target_w, target_h));
            let _ = window.set_position(LogicalPosition::new(target_x, target_y));
            let _ = window.show();
            if mode != "deck" && mode != "deck_idle" && mode != "deck_hover" {
                let _ = window.set_focus();
            }
        }
    }
    Ok(())
}


#[tauri::command]
pub fn set_note_pinned(app: AppHandle, pinned: bool) -> Result<(), String> {
    if let Some(window) = app.get_webview_window("deck") {
        #[cfg(target_os = "macos")]
        {
            if let Ok(ptr) = window.ns_window() {
                unsafe {
                    crate::native::macos::set_window_pinned_level(ptr, pinned);
                }
            }
        }
        let _ = window.set_always_on_top(pinned);
    }
    Ok(())
}
