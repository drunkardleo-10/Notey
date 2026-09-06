use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut, ShortcutState};

pub fn register_archive_hotkey(app: &AppHandle) -> Result<(), String> {
    let hotkey: Shortcut = "CommandOrControl+Alt+L"
        .parse()
        .map_err(|e| format!("{:?}", e))?;

    let app_handle = app.clone();
    let _ = app.global_shortcut().on_shortcut(hotkey, move |_app, _shortcut, event| {
        if event.state() == ShortcutState::Pressed {
            let _ = app_handle.emit("toggle-archive", ());
            if let Some(window) = app_handle.get_webview_window("deck") {
                let _ = window.show();
                let _ = window.set_focus();
            }
        }
    });

    Ok(())
}
