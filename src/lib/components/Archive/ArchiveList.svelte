<script lang="ts">
  import IconSearch from '$lib/components/Icons/IconSearch.svelte';
  import type { Note } from '$lib/types';

  interface Props {
    notes: Note[];
    selectedId: string | null;
    searchQuery: string;
    onselect: (note: Note) => void;
    onsearch: (query: string) => void;
  }

  let { notes, selectedId, searchQuery = $bindable(), onselect, onsearch }: Props = $props();

  function handleInput(e: Event) {
    const target = e.target as HTMLInputElement;
    searchQuery = target.value;
    onsearch(target.value);
  }
</script>

<aside class="archive-sidebar">
  <div class="search-box">
    <IconSearch size={14} color="#8C827A" />
    <input
      type="text"
      class="search-input"
      placeholder="Search"
      value={searchQuery}
      oninput={handleInput}
    />
  </div>

  <ul class="archive-items-list">
    {#each notes as note (note.id)}
      <li class="note-list-item">
        <button
          type="button"
          class="note-row"
          class:selected={note.id === selectedId}
          onclick={() => onselect(note)}
          aria-label={note.title || 'Untitled note'}
        >
          <div
            class="color-stripe"
            style="background-color: var(--color-{note.color});"
          ></div>
          <span class="note-row-title">{note.title || 'Untitled note'}</span>
        </button>
      </li>
    {/each}

    {#if notes.length === 0}
      <li class="empty-state">No archived notes found</li>
    {/if}
  </ul>
</aside>

<style>
  .archive-sidebar {
    width: 220px;
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 16px 12px;
    border-right: 1px solid rgba(44, 38, 34, 0.08);
    background-color: var(--color-cream);
    user-select: none;
  }

  .search-box {
    display: flex;
    align-items: center;
    gap: 8px;
    background-color: rgba(44, 38, 34, 0.06);
    border-radius: 10px;
    padding: 7px 12px;
  }

  .search-input {
    width: 100%;
    font-family: var(--font-ui);
    font-size: 13px;
    color: var(--color-text-primary);
    background: transparent;
    border: none;
    outline: none;
  }

  .search-input::placeholder {
    color: var(--color-text-muted);
  }

  .archive-items-list {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 4px;
    overflow-y: auto;
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .note-list-item {
    display: block;
    width: 100%;
  }

  .note-row {
    position: relative;
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 10px;
    border-radius: 8px;
    cursor: pointer;
    text-align: left;
    transition: background-color 0.12s ease;
    border: none;
    background: transparent;
    width: 100%;
  }

  .note-row:hover {
    background-color: rgba(44, 38, 34, 0.05);
  }

  .note-row.selected {
    background-color: #E7E1D7;
  }

  .color-stripe {
    width: 3.5px;
    height: 18px;
    border-radius: 2px;
    flex-shrink: 0;
  }

  .note-row-title {
    font-family: var(--font-ui);
    font-size: 13px;
    font-weight: 600;
    color: var(--color-text-primary);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    flex: 1;
  }

  .empty-state {
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--color-text-muted);
    text-align: center;
    padding: 24px 8px;
    list-style: none;
  }
</style>
