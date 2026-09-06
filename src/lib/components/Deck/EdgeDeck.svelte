<script lang="ts">
  import { onMount } from 'svelte';
  import { invoke } from '@tauri-apps/api/core';
  import { activeDeckNotes, createNote, loadNotes } from '$lib/stores/notes';
  import type { Note, NoteColor } from '$lib/types';
  import CollapsedTab from './CollapsedTab.svelte';
  import EdgeAnchor from './EdgeAnchor.svelte';

  interface Props {
    onSelectNote?: (note: Note) => void;
    isEditorOpen?: boolean;
  }

  let { onSelectNote, isEditorOpen = false }: Props = $props();

  let isDeckHovered = $state(false);
  let expandedNoteId = $state<string | null>(null);
  let leaveTimeout: ReturnType<typeof setTimeout> | null = null;
  let dwellTimeout: ReturnType<typeof setTimeout> | null = null;

  onMount(async () => {
    const loaded = await loadNotes();
    if (loaded.length === 0) {
      await createNote(
        'Getting started',
        'Hover the dots at the edge of the screen to open your deck.',
        'yellow'
      );
      await createNote(
        'Sprint planning',
        'Review current velocity and rotate backlog reviews.',
        'coral'
      );
      await createNote(
        'Book recommendations',
        'Read Designing Data-Intensive Applications and The Pragmatic Programmer.',
        'mint'
      );
    }
  });

  async function handleDeckMouseEnter() {
    if (leaveTimeout) {
      clearTimeout(leaveTimeout);
      leaveTimeout = null;
    }
    if (!isDeckHovered) {
      isDeckHovered = true;
      if (!isEditorOpen) {
        try {
          await invoke('set_window_mode', { mode: 'deck_hover' });
        } catch {
        }
      }
    }
  }

  function handleDeckMouseLeave() {
    if (dwellTimeout) {
      clearTimeout(dwellTimeout);
      dwellTimeout = null;
    }
    if (leaveTimeout) {
      clearTimeout(leaveTimeout);
    }
    leaveTimeout = setTimeout(async () => {
      isDeckHovered = false;
      expandedNoteId = null;
      if (!isEditorOpen) {
        try {
          await invoke('set_window_mode', { mode: 'deck_idle' });
        } catch {
        }
      }
    }, 220);
  }

  function handleTabMouseEnter(noteId: string) {
    if (leaveTimeout) {
      clearTimeout(leaveTimeout);
      leaveTimeout = null;
    }
    if (dwellTimeout) {
      clearTimeout(dwellTimeout);
      dwellTimeout = null;
    }
    dwellTimeout = setTimeout(() => {
      expandedNoteId = noteId;
    }, 700);
  }

  function handleTabMouseLeave(noteId: string) {
    if (dwellTimeout) {
      clearTimeout(dwellTimeout);
      dwellTimeout = null;
    }
    if (expandedNoteId === noteId) {
      expandedNoteId = null;
    }
  }

  async function handleAddNote() {
    const colors: NoteColor[] = ['yellow', 'coral', 'mint', 'blue', 'lavender'];
    const nextColor = colors[($activeDeckNotes.length) % colors.length];
    const newNote = await createNote('Untitled note', '', nextColor);
    onSelectNote?.(newNote);
  }
</script>

<div
  class="edge-deck-container"
  class:hovered={isDeckHovered}
  onmouseenter={handleDeckMouseEnter}
  onmouseleave={handleDeckMouseLeave}
  role="region"
  aria-label="Sticky notes edge deck"
>
  <div class="deck-column">
    <div class="tabs-list">
      {#each $activeDeckNotes as note (note.id)}
        <CollapsedTab
          {note}
          {isDeckHovered}
          isCardExpanded={expandedNoteId === note.id}
          onSelect={onSelectNote}
          onHover={() => handleTabMouseEnter(note.id)}
          onLeave={() => handleTabMouseLeave(note.id)}
        />
      {/each}
    </div>
    <EdgeAnchor
      {isDeckHovered}
      onAddNote={handleAddNote}
    />
  </div>
</div>

<style>
  .edge-deck-container {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    background-color: transparent;
    user-select: none;
    padding-right: 0;
    pointer-events: none;
  }

  .deck-column {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 12px;
    padding-right: 0;
    pointer-events: auto;
  }

  .tabs-list {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 6px;
  }
</style>
