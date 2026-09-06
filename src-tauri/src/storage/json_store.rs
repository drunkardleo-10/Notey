use std::fs;
use std::io::Write;
use std::path::PathBuf;
use tempfile::NamedTempFile;
use uuid::Uuid;

use crate::models::Note;

#[derive(Clone, Debug)]
pub struct JsonStore {
    base_path: PathBuf,
}

impl Default for JsonStore {
    fn default() -> Self {
        let app_support = dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("Notey")
            .join("notes");
        Self::new(app_support)
    }
}

impl JsonStore {
    pub fn new(base_path: PathBuf) -> Self {
        Self { base_path }
    }

    pub fn ensure_dir(&self) -> Result<(), String> {
        fs::create_dir_all(&self.base_path).map_err(|e| e.to_string())
    }

    pub fn get_note_path(&self, id: &Uuid) -> PathBuf {
        self.base_path.join(format!("{}.json", id))
    }

    pub fn save_note(&self, note: &Note) -> Result<(), String> {
        self.ensure_dir()?;
        let target_path = self.get_note_path(&note.id);
        let serialized = serde_json::to_vec_pretty(note).map_err(|e| e.to_string())?;

        let mut temp_file = NamedTempFile::new_in(&self.base_path).map_err(|e| e.to_string())?;
        temp_file.write_all(&serialized).map_err(|e| e.to_string())?;
        temp_file.flush().map_err(|e| e.to_string())?;
        temp_file
            .persist(&target_path)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn load_note(&self, id: &Uuid) -> Result<Note, String> {
        let path = self.get_note_path(id);
        if !path.exists() {
            return Err(format!("Note not found: {}", id));
        }
        let data = fs::read(&path).map_err(|e| e.to_string())?;
        let note: Note = serde_json::from_slice(&data).map_err(|e| e.to_string())?;
        Ok(note)
    }

    pub fn load_all_notes(&self) -> Result<Vec<Note>, String> {
        if !self.base_path.exists() {
            return Ok(Vec::new());
        }

        let mut notes = Vec::new();
        let entries = fs::read_dir(&self.base_path).map_err(|e| e.to_string())?;

        for entry in entries {
            let entry = entry.map_err(|e| e.to_string())?;
            let path = entry.path();
            if path.extension().and_then(|ext| ext.to_str()) == Some("json") {
                if let Ok(data) = fs::read(&path) {
                    if let Ok(note) = serde_json::from_slice::<Note>(&data) {
                        notes.push(note);
                    }
                }
            }
        }

        notes.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
        Ok(notes)
    }

    pub fn delete_note(&self, id: &Uuid) -> Result<bool, String> {
        let path = self.get_note_path(id);
        if path.exists() {
            fs::remove_file(&path).map_err(|e| e.to_string())?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    pub fn archive_note(&self, id: &Uuid) -> Result<Note, String> {
        let mut note = self.load_note(id)?;
        note.is_archived = true;
        note.mark_updated();
        self.save_note(&note)?;
        Ok(note)
    }

    pub fn restore_note(&self, id: &Uuid) -> Result<Note, String> {
        let mut note = self.load_note(id)?;
        note.is_archived = false;
        note.mark_updated();
        self.save_note(&note)?;
        Ok(note)
    }

    pub fn search_notes(&self, query: &str) -> Result<Vec<Note>, String> {
        let normalized = query.trim().to_lowercase();
        let all_notes = self.load_all_notes()?;

        if normalized.is_empty() {
            return Ok(all_notes);
        }

        let filtered = all_notes
            .into_iter()
            .filter(|n| {
                n.title.to_lowercase().contains(&normalized)
                    || n.body.to_lowercase().contains(&normalized)
            })
            .collect();

        Ok(filtered)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::NoteColor;
    use tempfile::tempdir;

    #[test]
    fn test_crud_and_atomic_persistence() {
        let dir = tempdir().expect("failed to create temp dir");
        let store = JsonStore::new(dir.path().to_path_buf());

        let mut note = Note::new(
            "Sprint Planning".to_string(),
            "- [ ] Review backlog\n- [ ] Assign tickets".to_string(),
            NoteColor::Yellow,
        );

        store.save_note(&note).expect("save should succeed");

        let loaded = store.load_note(&note.id).expect("load should succeed");
        assert_eq!(loaded.title, "Sprint Planning");
        assert_eq!(loaded.color, NoteColor::Yellow);
        assert!(!loaded.is_archived);

        note.title = "Sprint Planning Updated".to_string();
        note.color = NoteColor::Mint;
        store.save_note(&note).expect("update should succeed");

        let updated = store.load_note(&note.id).expect("load updated note");
        assert_eq!(updated.title, "Sprint Planning Updated");
        assert_eq!(updated.color, NoteColor::Mint);

        let archived = store.archive_note(&note.id).expect("archive note");
        assert!(archived.is_archived);

        let restored = store.restore_note(&note.id).expect("restore note");
        assert!(!restored.is_archived);

        let deleted = store.delete_note(&note.id).expect("delete note");
        assert!(deleted);
        assert!(store.load_note(&note.id).is_err());
    }

    #[test]
    fn test_batch_creation_and_search() {
        let dir = tempdir().expect("failed to create temp dir");
        let store = JsonStore::new(dir.path().to_path_buf());

        for i in 0..10 {
            let color = match i % 5 {
                0 => NoteColor::Yellow,
                1 => NoteColor::Coral,
                2 => NoteColor::Mint,
                3 => NoteColor::Blue,
                _ => NoteColor::Lavender,
            };

            let note = Note::new(
                format!("Note Number {}", i),
                format!("Content markdown body for note index {}", i),
                color,
            );
            store.save_note(&note).expect("save note batch");
        }

        let all = store.load_all_notes().expect("load all notes");
        assert_eq!(all.len(), 10);

        let search_title = store.search_notes("Number 3").expect("search by title");
        assert_eq!(search_title.len(), 1);
        assert_eq!(search_title[0].title, "Note Number 3");

        let search_body = store.search_notes("markdown body").expect("search by body");
        assert_eq!(search_body.len(), 10);
    }
}
