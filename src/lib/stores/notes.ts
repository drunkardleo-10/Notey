import { writable, derived } from 'svelte/store';
import { invoke } from '@tauri-apps/api/core';
import type { Note, NoteColor } from '$lib/types';

export const notes = writable<Note[]>([]);
export const searchQuery = writable<string>('');

export const activeDeckNotes = derived(notes, ($notes) =>
  $notes.filter((note) => !note.isArchived)
);

export const archivedNotes = derived(notes, ($notes) =>
  $notes.filter((note) => note.isArchived)
);

export async function loadNotes(): Promise<Note[]> {
  const allNotes = await invoke<Note[]>('get_all_notes');
  notes.set(allNotes);
  return allNotes;
}

export async function createNote(title: string, body: string, color: NoteColor): Promise<Note> {
  const newNote = await invoke<Note>('create_note', { title, body, color });
  notes.update((prev) => [newNote, ...prev]);
  return newNote;
}

export async function saveNote(note: Note): Promise<Note> {
  const updated = await invoke<Note>('save_note', { note });
  notes.update((prev) =>
    prev.map((item) => (item.id === updated.id ? updated : item))
  );
  return updated;
}

export async function deleteNote(id: string): Promise<boolean> {
  const success = await invoke<boolean>('delete_note', { id });
  if (success) {
    notes.update((prev) => prev.filter((item) => item.id !== id));
  }
  return success;
}

export async function archiveNote(id: string): Promise<Note> {
  const archived = await invoke<Note>('archive_note', { id });
  notes.update((prev) =>
    prev.map((item) => (item.id === archived.id ? archived : item))
  );
  return archived;
}

export async function restoreNote(id: string): Promise<Note> {
  const restored = await invoke<Note>('restore_note', { id });
  notes.update((prev) =>
    prev.map((item) => (item.id === restored.id ? restored : item))
  );
  return restored;
}

export async function searchNotes(query: string): Promise<Note[]> {
  const results = await invoke<Note[]>('search_notes', { query });
  return results;
}
