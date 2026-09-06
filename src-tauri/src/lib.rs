pub mod commands;
pub mod hotkey;
pub mod models;
pub mod native;
pub mod storage;

use commands::notes::AppState;
use storage::JsonStore;
use tauri::menu::{Menu, MenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::{Emitter, Manager};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let store = JsonStore::default();
    let app_state = AppState::new(store);

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            Some(vec!["--autostart"]),
        ))
        .manage(app_state)
        .setup(|app| {
            if let Some(window) = app.get_webview_window("deck") {
                #[cfg(target_os = "macos")]
                {
                    if let Ok(ptr) = window.ns_window() {
                        unsafe {
                            native::macos::configure_edge_deck_panel(ptr);
                        }
                    }
                }
            }

            let _ = hotkey::register_archive_hotkey(app.handle());

            let new_i = MenuItem::with_id(app, "new", "New Note", true, None::<&str>)?;
            let deck_i = MenuItem::with_id(app, "deck", "Show Deck", true, None::<&str>)?;
            let archive_i = MenuItem::with_id(app, "archive", "Open Archive (⌥⌘L)", true, None::<&str>)?;
            let quit_i = MenuItem::with_id(app, "quit", "Quit Notey", true, None::<&str>)?;
            let tray_menu = Menu::with_items(app, &[&new_i, &deck_i, &archive_i, &quit_i])?;

            let mut tray_builder = TrayIconBuilder::new()
                .menu(&tray_menu)
                .show_menu_on_left_click(true)
                .on_menu_event(|app, event| {
                    match event.id.as_ref() {
                        "quit" => {
                            app.exit(0);
                        }
                        "deck" => {
                            if let Some(w) = app.get_webview_window("deck") {
                                let _ = w.show();
                                let _ = w.set_focus();
                            }
                        }
                        "archive" => {
                            let _ = app.emit("toggle-archive", ());
                        }
                        "new" => {
                            let _ = app.emit("create-new-note", ());
                        }
                        _ => {}
                    }
                });

            if let Some(icon) = app.default_window_icon() {
                tray_builder = tray_builder.icon(icon.clone());
            }

            let _ = tray_builder.build(app)?;

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::notes::get_all_notes,
            commands::notes::get_note,
            commands::notes::save_note,
            commands::notes::create_note,
            commands::notes::delete_note,
            commands::notes::archive_note,
            commands::notes::restore_note,
            commands::notes::search_notes,
            commands::window::setup_edge_deck,
            commands::window::set_window_mode,
            commands::window::set_note_pinned
        ])
        .run(tauri::generate_context!())
        .expect("error while running notey application");
}
