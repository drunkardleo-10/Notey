<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import EditorHeader from './EditorHeader.svelte';
  import EditorToolbar from './EditorToolbar.svelte';
  import CartaEditorWrapper from './CartaEditorWrapper.svelte';
  import { saveNote, deleteNote, archiveNote } from '$lib/stores/notes';
  import type { Note, NoteColor } from '$lib/types';

  interface Props {
    note: Note;
    onclose?: () => void;
  }

  let { note = $bindable(), onclose }: Props = $props();

  let autosaveStatus = $state('Saved · now');
  let saveTimer: ReturnType<typeof setTimeout> | null = null;
  let editorRef: { toggleChecklist: () => void } | null = $state(null);

  function triggerAutosave() {
    autosaveStatus = 'Saving...';
    if (saveTimer) {
      clearTimeout(saveTimer);
    }
    saveTimer = setTimeout(async () => {
      try {
        await saveNote(note);
        autosaveStatus = 'Saved · now';
      } catch {
        autosaveStatus = 'Save failed';
      }
    }, 500);
  }

  function handleTitleChange(newTitle: string) {
    note.title = newTitle;
    triggerAutosave();
  }

  function handleBodyChange(newBody: string) {
    note.body = newBody;
    triggerAutosave();
  }

  import { invoke } from '@tauri-apps/api/core';

  function handleColorChange(newColor: NoteColor) {
    note.color = newColor;
    triggerAutosave();
  }

  async function handleTogglePin() {
    note.isPinned = !note.isPinned;
    try {
      await invoke('set_note_pinned', { pinned: note.isPinned });
    } catch {
    }
    triggerAutosave();
  }

  function handleInsertChecklist() {
    editorRef?.toggleChecklist();
  }

  let isDiscarding = false;
  let isClosing = $state(false);

  function handleTriggerClose() {
    if (isClosing) return;
    isClosing = true;
    setTimeout(() => {
      onclose?.();
    }, 200);
  }

  async function handleDelete() {
    isDiscarding = true;
    if (saveTimer) {
      clearTimeout(saveTimer);
      saveTimer = null;
    }
    await deleteNote(note.id);
    handleTriggerClose();
  }

  async function handleComplete() {
    isDiscarding = true;
    if (saveTimer) {
      clearTimeout(saveTimer);
      saveTimer = null;
    }
    await archiveNote(note.id);
    handleTriggerClose();
  }

  let isArmed = $state(false);
  let armTimer: ReturnType<typeof setTimeout> | null = null;

  function handleKeyDown(e: KeyboardEvent) {
    if (e.key === 'Escape' || (e.metaKey && e.key === 'w')) {
      e.preventDefault();
      handleTriggerClose();
    }
  }

  function handleWindowBlur() {
    if (note.isPinned) return;
    if (isArmed && !isClosing) {
      handleTriggerClose();
    }
  }

  function handleGlobalPointerDown(e: MouseEvent) {
    if (note.isPinned) return;
    if (!isArmed || isClosing) return;
    const target = e.target as HTMLElement;
    if (target?.closest?.('.deck-column')) {
      return;
    }
    const editorEl = document.querySelector('.note-editor-window');
    if (editorEl && !editorEl.contains(target)) {
      handleTriggerClose();
    }
  }

  onMount(async () => {
    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('blur', handleWindowBlur);
    window.addEventListener('pointerdown', handleGlobalPointerDown);

    if (note.isPinned) {
      try {
        await invoke('set_note_pinned', { pinned: true });
      } catch {
      }
    }

    armTimer = setTimeout(() => {
      isArmed = true;
    }, 150);
  });

  onDestroy(async () => {
    window.removeEventListener('keydown', handleKeyDown);
    window.removeEventListener('blur', handleWindowBlur);
    window.removeEventListener('pointerdown', handleGlobalPointerDown);
    try {
      await invoke('set_note_pinned', { pinned: false });
    } catch {
    }
    window.removeEventListener('pointermove', handlePointerMove);
    window.removeEventListener('pointerup', handlePointerUp);
    if (armTimer) {
      clearTimeout(armTimer);
    }
    if (saveTimer) {
      clearTimeout(saveTimer);
      if (!isDiscarding) {
        saveNote(note);
      }
    }
  });

  let dragX = $state(0);
  let dragY = $state(0);
  let isDragging = false;
  let startPointerX = 0;
  let startPointerY = 0;
  let startDragX = 0;
  let startDragY = 0;

  function handleGripDragStart(e: PointerEvent) {
    if (e.button !== 0) return;
    isDragging = true;
    startPointerX = e.clientX;
    startPointerY = e.clientY;
    startDragX = dragX;
    startDragY = dragY;

    window.addEventListener('pointermove', handlePointerMove);
    window.addEventListener('pointerup', handlePointerUp);
  }

  function handlePointerMove(e: PointerEvent) {
    if (!isDragging) return;
    dragX = startDragX + (e.clientX - startPointerX);
    dragY = startDragY + (e.clientY - startPointerY);
  }

  function handlePointerUp() {
    isDragging = false;
    window.removeEventListener('pointermove', handlePointerMove);
    window.removeEventListener('pointerup', handlePointerUp);
  }
</script>

<div
  class="note-editor-window"
  class:closing={isClosing}
  class:dragged={dragX !== 0 || dragY !== 0}
  style="background-color: var(--color-{note.color}); {dragX !== 0 || dragY !== 0 ? `transform: translate3d(${dragX}px, ${dragY}px, 0) !important;` : ''}"
  role="dialog"
  aria-label="Note editor"
>
  <EditorHeader
    title={note.title}
    isPinned={note.isPinned}
    {autosaveStatus}
    ontitlechange={handleTitleChange}
    ontogglepin={handleTogglePin}
    onclose={handleTriggerClose}
    ondragstart={handleGripDragStart}
  />

  <div class="editor-body-zone">
    <CartaEditorWrapper
      bind:this={editorRef}
      bind:value={note.body}
      onchange={handleBodyChange}
    />
  </div>

  <EditorToolbar
    color={note.color}
    isChecklist={note.isChecklist}
    oncolorchange={handleColorChange}
    ontogglechecklist={handleInsertChecklist}
    ondelete={handleDelete}
    oncomplete={handleComplete}
    onclose={handleTriggerClose}
  />
</div>

<style>
  .note-editor-window {
    width: 380px;
    height: 400px;
    border-radius: 20px;
    display: flex;
    flex-direction: column;
    box-shadow: 0 16px 40px rgba(44, 38, 34, 0.22);
    overflow: hidden;
    user-select: none;
    transition: background-color 0.4s cubic-bezier(0.25, 1, 0.5, 1),
                box-shadow 0.3s ease;
    will-change: background-color;
    animation: editorPop 0.24s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .note-editor-window.dragged {
    animation: none !important;
  }

  .note-editor-window.closing {
    animation: editorSlideOut 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
    pointer-events: none;
  }

  @keyframes editorPop {
    from {
      opacity: 0;
      transform: translateX(20px) scale(0.96);
    }
    to {
      opacity: 1;
      transform: translateX(0) scale(1);
    }
  }

  @keyframes editorSlideOut {
    from {
      opacity: 1;
      transform: translateX(0) scale(1);
    }
    to {
      opacity: 0;
      transform: translateX(24px) scale(0.96);
    }
  }

  .editor-body-zone {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 0;
    overflow: hidden;
    padding: 0;
  }
</style>
