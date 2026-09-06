use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum NoteColor {
    Yellow,
    Coral,
    Mint,
    Blue,
    Lavender,
}

impl Default for NoteColor {
    fn default() -> Self {
        NoteColor::Yellow
    }
}

impl NoteColor {
    pub fn hex_code(&self) -> &'static str {
        match self {
            NoteColor::Yellow => "#FDC844",
            NoteColor::Coral => "#FF8A80",
            NoteColor::Mint => "#80E5D0",
            NoteColor::Blue => "#82B1FF",
            NoteColor::Lavender => "#CE93D8",
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Note {
    pub id: Uuid,
    pub title: String,
    pub body: String,
    pub color: NoteColor,
    pub is_checklist: bool,
    pub is_pinned: bool,
    pub is_archived: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Note {
    pub fn new(title: String, body: String, color: NoteColor) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            title,
            body,
            color,
            is_checklist: false,
            is_pinned: false,
            is_archived: false,
            created_at: now,
            updated_at: now,
        }
    }

    pub fn mark_updated(&mut self) {
        self.updated_at = Utc::now();
    }
}
