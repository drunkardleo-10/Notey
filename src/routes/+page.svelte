<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { invoke } from '@tauri-apps/api/core';
  import { listen, type UnlistenFn } from '@tauri-apps/api/event';
  import { enable, isEnabled } from '@tauri-apps/plugin-autostart';
  import EdgeDeck from '$lib/components/Deck/EdgeDeck.svelte';
  import NoteEditor from '$lib/components/Editor/NoteEditor.svelte';
  import ArchiveWindow from '$lib/components/Archive/ArchiveWindow.svelte';
  import OnboardingWindow from '$lib/components/Onboarding/OnboardingWindow.svelte';
  import { createNote } from '$lib/stores/notes';
  import type { Note, NoteColor } from '$lib/types';

  let activeEditingNote = $state<Note | null>(null);
  let isArchiveOpen = $state(false);
  let showOnboarding = $state(false);
  let unlistenToggle: UnlistenFn | null = null;
  let unlistenCreate: UnlistenFn | null = null;

  onMount(async () => {
    const completed = localStorage.getItem('notey-has-completed-onboarding');
    if (!completed) {
      showOnboarding = true;
      try {
        await invoke('set_window_mode', { mode: 'onboarding' });
      } catch {
      }
    } else {
      try {
        await invoke('set_window_mode', { mode: 'deck' });
      } catch {
      }
    }

    try {
      unlistenToggle = await listen('toggle-archive', async () => {
        isArchiveOpen = !isArchiveOpen;
        if (isArchiveOpen) {
          activeEditingNote = null;
          showOnboarding = false;
          await invoke('set_window_mode', { mode: 'archive' });
        } else {
          await invoke('set_window_mode', { mode: 'deck' });
        }
      });

      unlistenCreate = await listen('create-new-note', async () => {
        const colors: NoteColor[] = ['yellow', 'coral', 'mint', 'blue', 'lavender'];
        const newNote = await createNote('Untitled note', '', colors[0]);
        activeEditingNote = newNote;
        isArchiveOpen = false;
        showOnboarding = false;
        await invoke('set_window_mode', { mode: 'editor' });
      });
    } catch {
    }

    window.addEventListener('keydown', handleGlobalKey);
  });

  onDestroy(() => {
    unlistenToggle?.();
    unlistenCreate?.();
    window.removeEventListener('keydown', handleGlobalKey);
  });

  async function handleGlobalKey(e: KeyboardEvent) {
    if (e.altKey && e.metaKey && (e.key === 'l' || e.key === 'L')) {
      e.preventDefault();
      isArchiveOpen = !isArchiveOpen;
      if (isArchiveOpen) {
        activeEditingNote = null;
        showOnboarding = false;
        await invoke('set_window_mode', { mode: 'archive' });
      } else {
        await invoke('set_window_mode', { mode: 'deck' });
      }
    }
  }

  async function handleSelectNote(note: Note) {
    activeEditingNote = note;
    isArchiveOpen = false;
    await invoke('set_window_mode', { mode: 'editor' });
  }

  async function handleCloseEditor() {
    activeEditingNote = null;
    await invoke('set_window_mode', { mode: 'deck' });
  }

  async function handleCloseArchive() {
    isArchiveOpen = false;
    await invoke('set_window_mode', { mode: 'deck' });
  }

  async function handleCompleteOnboarding(addToLogin: boolean) {
    localStorage.setItem('notey-has-completed-onboarding', 'true');
    showOnboarding = false;
    await invoke('set_window_mode', { mode: 'deck' });
    if (addToLogin) {
      try {
        const enabled = await isEnabled();
        if (!enabled) {
          await enable();
        }
      } catch {
      }
    }
  }

  async function handleSkipOnboarding() {
    localStorage.setItem('notey-has-completed-onboarding', 'true');
    showOnboarding = false;
    await invoke('set_window_mode', { mode: 'deck' });
  }
</script>

<main
  class="app-root"
  class:centered={showOnboarding || isArchiveOpen}
  class:docked={!showOnboarding && !isArchiveOpen}
>
  {#if showOnboarding}
    <div class="modal-overlay">
      <OnboardingWindow
        oncomplete={handleCompleteOnboarding}
        onskip={handleSkipOnboarding}
      />
    </div>
  {:else if isArchiveOpen}
    <div class="modal-overlay">
      <ArchiveWindow onclose={handleCloseArchive} />
    </div>
  {:else}
    <div class="dock-workspace">
      {#if activeEditingNote}
        <div class="editor-overlay">
          <NoteEditor
            bind:note={activeEditingNote}
            onclose={handleCloseEditor}
          />
        </div>
      {/if}
      <div class="deck-wrapper">
        <EdgeDeck
          onSelectNote={handleSelectNote}
          isEditorOpen={activeEditingNote !== null}
        />
      </div>
    </div>
  {/if}
</main>

<style>
  :global(html), :global(body) {
    background-color: transparent !important;
    overflow: hidden;
    margin: 0;
    padding: 0;
  }

  .app-root {
    width: 100vw;
    height: 100vh;
    background-color: transparent;
    display: flex;
    overflow: hidden;
    pointer-events: none;
  }

  .app-root.centered {
    justify-content: center;
    align-items: center;
    padding: 0;
  }

  .app-root.docked {
    justify-content: flex-end;
    align-items: center;
    padding-right: 0;
  }

  .dock-workspace {
    position: relative;
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    padding-right: 0;
    pointer-events: none;
  }

  .deck-wrapper {
    position: absolute;
    right: 0;
    top: 0;
    bottom: 0;
    width: 48px;
    display: flex;
    align-items: center;
    justify-content: flex-end;
    pointer-events: none;
  }

  .modal-overlay {
    pointer-events: auto;
    animation: modalPop 0.22s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .editor-overlay {
    position: absolute;
    right: 64px;
    top: 50%;
    transform: translateY(-50%);
    pointer-events: auto;
  }

  @keyframes modalPop {
    from {
      opacity: 0;
      transform: scale(0.95);
    }
    to {
      opacity: 1;
      transform: scale(1);
    }
  }
</style>
