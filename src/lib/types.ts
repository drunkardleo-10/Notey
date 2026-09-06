export type NoteColor = 'yellow' | 'coral' | 'mint' | 'blue' | 'lavender';

export interface Note {
  id: string;
  title: string;
  body: string;
  color: NoteColor;
  isChecklist: boolean;
  isPinned: boolean;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ChecklistItem {
  id: string;
  text: string;
  isCompleted: boolean;
}
