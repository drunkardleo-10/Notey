<script lang="ts">
  import ColorSwatchPicker from './ColorSwatchPicker.svelte';
  import IconChecklist from '$lib/components/Icons/IconChecklist.svelte';
  import type { NoteColor } from '$lib/types';

  interface Props {
    color: NoteColor;
    isChecklist: boolean;
    oncolorchange: (color: NoteColor) => void;
    ontogglechecklist: () => void;
    ondelete: () => void;
    oncomplete: () => void;
    onclose: () => void;
  }

  let {
    color,
    isChecklist,
    oncolorchange,
    ontogglechecklist,
    ondelete,
    oncomplete,
    onclose
  }: Props = $props();
</script>

<footer class="editor-toolbar">
  <div class="toolbar-left">
    <ColorSwatchPicker selected={color} onselect={oncolorchange} />
    <button
      type="button"
      class="icon-toggle-btn"
      class:active={isChecklist}
      onclick={ontogglechecklist}
      aria-label="Toggle checklist mode"
    >
      <IconChecklist size={16} color="#2C2622" />
    </button>
  </div>

  <div class="toolbar-right">
    <button type="button" class="action-pill delete-pill" onclick={ondelete}>
      Delete
    </button>
    <button type="button" class="action-pill complete-pill" onclick={oncomplete}>
      Complete
    </button>
    <button type="button" class="action-pill close-pill" onclick={onclose}>
      Close
    </button>
  </div>
</footer>

<style>
  .editor-toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 14px;
    background-color: rgba(44, 38, 34, 0.04);
    border-top: 1px solid rgba(44, 38, 34, 0.08);
    border-radius: 0 0 20px 20px;
    user-select: none;
    box-sizing: border-box;
    transition: background-color 0.4s cubic-bezier(0.25, 1, 0.5, 1);
  }

  .toolbar-left {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .icon-toggle-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 3px;
    border-radius: 5px;
    cursor: pointer;
    transition: background-color 0.15s ease, transform 0.15s ease;
  }

  .icon-toggle-btn:hover {
    background-color: rgba(44, 38, 34, 0.08);
    transform: scale(1.08);
  }

  .icon-toggle-btn.active {
    background-color: rgba(44, 38, 34, 0.14);
  }

  .toolbar-right {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }

  .action-pill {
    font-family: var(--font-ui);
    font-size: 11.5px;
    font-weight: 600;
    padding: 5px 8px;
    border-radius: 7px;
    cursor: pointer;
    white-space: nowrap;
    transition: opacity 0.15s ease, transform 0.12s ease;
  }

  .action-pill:hover {
    opacity: 0.88;
    transform: translateY(-1px);
  }

  .action-pill:active {
    transform: translateY(0);
  }

  .delete-pill {
    background-color: rgba(211, 47, 47, 0.12);
    color: #C62828;
  }

  .complete-pill {
    background-color: rgba(44, 38, 34, 0.08);
    color: var(--color-text-primary);
  }

  .close-pill {
    background-color: transparent;
    border: 1px solid rgba(44, 38, 34, 0.18);
    color: var(--color-text-primary);
  }
</style>
