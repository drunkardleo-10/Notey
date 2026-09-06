use std::sync::Mutex;
use tauri::State;
use uuid::Uuid;

use crate::models::{Note, NoteColor};
use crate::storage::JsonStore;

pub struct AppState {
    pub store: Mutex<JsonStore>,
}

impl AppState {
    pub fn new(store: JsonStore) -> Self {
        Self {
            store: Mutex::new(store),
        }
    }
}

#[tauri::command]
pub fn get_all_notes(state: State<'_, AppState>) -> Result<Vec<Note>, String> {
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.load_all_notes()
}

#[tauri::command]
pub fn get_note(id: String, state: State<'_, AppState>) -> Result<Note, String> {
    let uuid = Uuid::parse_str(&id).map_err(|e| e.to_string())?;
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.load_note(&uuid)
}

#[tauri::command]
pub fn save_note(note: Note, state: State<'_, AppState>) -> Result<Note, String> {
    let mut note = note;
    note.mark_updated();
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.save_note(&note)?;
    Ok(note)
}

#[tauri::command]
pub fn create_note(
    title: String,
    body: String,
    color: NoteColor,
    state: State<'_, AppState>,
) -> Result<Note, String> {
    let note = Note::new(title, body, color);
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.save_note(&note)?;
    Ok(note)
}

#[tauri::command]
pub fn delete_note(id: String, state: State<'_, AppState>) -> Result<bool, String> {
    let uuid = Uuid::parse_str(&id).map_err(|e| e.to_string())?;
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.delete_note(&uuid)
}

#[tauri::command]
pub fn archive_note(id: String, state: State<'_, AppState>) -> Result<Note, String> {
    let uuid = Uuid::parse_str(&id).map_err(|e| e.to_string())?;
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.archive_note(&uuid)
}

#[tauri::command]
pub fn restore_note(id: String, state: State<'_, AppState>) -> Result<Note, String> {
    let uuid = Uuid::parse_str(&id).map_err(|e| e.to_string())?;
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.restore_note(&uuid)
}

#[tauri::command]
pub fn search_notes(query: String, state: State<'_, AppState>) -> Result<Vec<Note>, String> {
    let store = state.store.lock().map_err(|e| e.to_string())?;
    store.search_notes(&query)
}
