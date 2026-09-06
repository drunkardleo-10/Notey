<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { archivedNotes, restoreNote, deleteNote, loadNotes } from '$lib/stores/notes';
  import type { Note } from '$lib/types';
  import ArchiveList from './ArchiveList.svelte';
  import ArchiveDetail from './ArchiveDetail.svelte';

  interface Props {
    onclose?: () => void;
  }

  let { onclose }: Props = $props();

  let searchQuery = $state('');
  let selectedNoteId = $state<string | null>(null);

  let filteredNotes = $derived.by(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return $archivedNotes;
    return $archivedNotes.filter(
      (n) => n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q)
    );
  });

  let selectedNote = $derived.by(() => {
    if (filteredNotes.length === 0) return null;
    return filteredNotes.find((n) => n.id === selectedNoteId) ?? filteredNotes[0];
  });

  onMount(async () => {
    await loadNotes();
    if ($archivedNotes.length > 0) {
      selectedNoteId = $archivedNotes[0].id;
    }
  });

  function handleSelect(note: Note) {
    selectedNoteId = note.id;
  }

  function handleSearch(query: string) {
    searchQuery = query;
  }

  async function handleRestore(id: string) {
    await restoreNote(id);
    if (selectedNoteId === id) {
      const remaining = $archivedNotes.filter((n) => n.id !== id);
      selectedNoteId = remaining.length > 0 ? remaining[0].id : null;
    }
  }

  async function handleDelete(id: string) {
    await deleteNote(id);
    if (selectedNoteId === id) {
      const remaining = $archivedNotes.filter((n) => n.id !== id);
      selectedNoteId = remaining.length > 0 ? remaining[0].id : null;
    }
  }

  function handleKeyDown(e: KeyboardEvent) {
    if (e.key === 'Escape' || (e.metaKey && e.key === 'w')) {
      e.preventDefault();
      onclose?.();
    }
  }

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown);
  });
</script>

<div class="archive-window" role="dialog" aria-label="Archive">
  <header class="archive-titlebar">
    <div class="traffic-lights">
      <button
        type="button"
        class="traffic-dot close-dot"
        onclick={onclose}
        aria-label="Close archive"
      ></button>
      <span class="traffic-dot min-dot"></span>
      <span class="traffic-dot max-dot"></span>
    </div>
    <span class="window-title">Archive</span>
    <div class="titlebar-spacer"></div>
  </header>

  <div class="archive-split-body">
    <ArchiveList
      notes={filteredNotes}
      selectedId={selectedNote?.id ?? null}
      bind:searchQuery
      onselect={handleSelect}
      onsearch={handleSearch}
    />
    <ArchiveDetail
      note={selectedNote}
      onrestore={handleRestore}
      ondelete={handleDelete}
    />
  </div>
</div>

<style>
  .archive-window {
    width: 620px;
    height: 440px;
    border-radius: 20px;
    background-color: var(--color-cream);
    display: flex;
    flex-direction: column;
    box-shadow: 0 20px 50px rgba(44, 38, 34, 0.28);
    overflow: hidden;
    user-select: none;
    border: 1px solid rgba(44, 38, 34, 0.12);
  }

  .archive-titlebar {
    height: 38px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 16px;
    border-bottom: 1px solid rgba(44, 38, 34, 0.08);
    background-color: var(--color-cream);
  }

  .traffic-lights {
    display: flex;
    gap: 7px;
  }

  .traffic-dot {
    width: 11px;
    height: 11px;
    border-radius: 50%;
    border: none;
    padding: 0;
  }

  .close-dot {
    background-color: #FF5F56;
    cursor: pointer;
  }

  .min-dot {
    background-color: #FFBD2E;
  }

  .max-dot {
    background-color: #27C93F;
  }

  .window-title {
    font-family: var(--font-ui);
    font-size: 13px;
    font-weight: 700;
    color: var(--color-text-primary);
  }

  .titlebar-spacer {
    width: 50px;
  }

  .archive-split-body {
    flex: 1;
    display: flex;
    min-height: 0;
  }
</style>
