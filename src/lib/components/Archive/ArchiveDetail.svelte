<script lang="ts">
  import type { Note } from '$lib/types';

  interface Props {
    note: Note | null;
    onrestore: (id: string) => void;
    ondelete: (id: string) => void;
  }

  let { note, onrestore, ondelete }: Props = $props();
</script>

<div class="archive-detail-container">
  {#if note}
    <div
      class="detail-sticky-card"
      style="background-color: var(--color-{note.color});"
    >
      <div class="detail-header">
        <h2 class="detail-title">{note.title || 'Untitled note'}</h2>
      </div>

      <div class="detail-body">
        {note.body}
      </div>

      <div class="detail-actions">
        <button
          type="button"
          class="btn-delete"
          onclick={() => ondelete(note.id)}
        >
          Delete
        </button>
        <button
          type="button"
          class="btn-restore"
          onclick={() => onrestore(note.id)}
        >
          Restore to deck
        </button>
      </div>
    </div>
  {:else}
    <div class="no-selection">
      Select an archived note to read or restore
    </div>
  {/if}
</div>

<style>
  .archive-detail-container {
    flex: 1;
    height: 100%;
    padding: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--color-cream);
  }

  .detail-sticky-card {
    width: 100%;
    height: 100%;
    border-radius: 18px;
    padding: 20px;
    display: flex;
    flex-direction: column;
    box-shadow: 0 8px 24px rgba(44, 38, 34, 0.12);
    user-select: none;
    overflow: hidden;
  }

  .detail-header {
    margin-bottom: 12px;
  }

  .detail-title {
    font-family: var(--font-ui);
    font-size: 16px;
    font-weight: 700;
    color: var(--color-text-primary);
  }

  .detail-body {
    flex: 1;
    font-family: var(--font-note);
    font-size: 15px;
    line-height: 1.5;
    color: var(--color-text-primary);
    white-space: pre-wrap;
    word-break: break-word;
    overflow-y: auto;
  }

  .detail-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    padding-top: 12px;
  }

  .btn-delete {
    font-family: var(--font-ui);
    font-size: 12px;
    font-weight: 600;
    padding: 6px 14px;
    border-radius: 8px;
    background-color: rgba(211, 47, 47, 0.1);
    color: #C62828;
    cursor: pointer;
    transition: opacity 0.15s ease;
  }

  .btn-delete:hover {
    opacity: 0.85;
  }

  .btn-restore {
    font-family: var(--font-ui);
    font-size: 12px;
    font-weight: 700;
    padding: 6px 16px;
    border-radius: 8px;
    background-color: rgba(44, 38, 34, 0.1);
    color: var(--color-text-primary);
    cursor: pointer;
    transition: background-color 0.15s ease;
  }

  .btn-restore:hover {
    background-color: rgba(44, 38, 34, 0.18);
  }

  .no-selection {
    font-family: var(--font-ui);
    font-size: 13px;
    color: var(--color-text-muted);
  }
</style>
