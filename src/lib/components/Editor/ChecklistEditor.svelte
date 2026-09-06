<script lang="ts">
  import { markdownToChecklist, checklistToMarkdown } from '$lib/utils/markdown';
  import IconGripDots from '$lib/components/Icons/IconGripDots.svelte';
  import type { ChecklistItem } from '$lib/types';

  interface Props {
    markdown: string;
    onchange?: (val: string) => void;
  }

  let { markdown = $bindable(), onchange }: Props = $props();

  let items = $state<ChecklistItem[]>(markdownToChecklist(markdown));
  let inputElements: (HTMLInputElement | null)[] = $state([]);
  let draggedIndex = $state<number | null>(null);

  function notifyChange() {
    const serialized = checklistToMarkdown(items);
    markdown = serialized;
    onchange?.(serialized);
  }

  function toggleItem(index: number) {
    items[index].isCompleted = !items[index].isCompleted;
    notifyChange();
  }

  function handleKeyDown(e: KeyboardEvent, index: number) {
    if (e.key === 'Enter') {
      e.preventDefault();
      const newItem: ChecklistItem = {
        id: `item-${Date.now()}-${Math.random()}`,
        text: '',
        isCompleted: false,
      };
      items.splice(index + 1, 0, newItem);
      notifyChange();

      setTimeout(() => {
        inputElements[index + 1]?.focus();
      }, 10);
    } else if (e.key === 'Backspace' && items[index].text === '' && items.length > 1) {
      e.preventDefault();
      items.splice(index, 1);
      notifyChange();

      const prevIndex = Math.max(0, index - 1);
      setTimeout(() => {
        inputElements[prevIndex]?.focus();
      }, 10);
    }
  }

  function handleDragStart(e: DragEvent, index: number) {
    draggedIndex = index;
    if (e.dataTransfer) {
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', String(index));
    }
  }

  function handleDragOver(e: DragEvent) {
    e.preventDefault();
    if (e.dataTransfer) {
      e.dataTransfer.dropEffect = 'move';
    }
  }

  function handleDrop(e: DragEvent, targetIndex: number) {
    e.preventDefault();
    if (draggedIndex !== null && draggedIndex !== targetIndex) {
      const moved = items.splice(draggedIndex, 1)[0];
      items.splice(targetIndex, 0, moved);
      notifyChange();
    }
    draggedIndex = null;
  }
</script>

<div class="checklist-container" role="list">
  {#each items as item, index (item.id)}
    <div
      class="checklist-row"
      class:completed={item.isCompleted}
      class:dragging={draggedIndex === index}
      ondragover={handleDragOver}
      ondrop={(e) => handleDrop(e, index)}
      role="listitem"
    >
      <div
        class="drag-handle"
        draggable="true"
        ondragstart={(e) => handleDragStart(e, index)}
        role="button"
        tabindex="0"
        aria-label="Drag to reorder"
      >
        <IconGripDots size={12} color="rgba(44, 38, 34, 0.3)" />
      </div>

      <button
        type="button"
        class="checkbox-btn"
        onclick={() => toggleItem(index)}
        aria-label={item.isCompleted ? "Mark incomplete" : "Mark complete"}
      >
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
          <rect
            x="1.5"
            y="1.5"
            width="15"
            height="15"
            rx="4"
            stroke="currentColor"
            stroke-width="1.8"
            fill={item.isCompleted ? "currentColor" : "none"}
          />
          {#if item.isCompleted}
            <path
              d="M4.5 9.5L7.5 12.5L13.5 5.5"
              stroke="#FDC844"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          {/if}
        </svg>
      </button>

      <input
        type="text"
        class="item-input"
        placeholder="List item..."
        bind:value={item.text}
        bind:this={inputElements[index]}
        oninput={notifyChange}
        onkeydown={(e) => handleKeyDown(e, index)}
      />
    </div>
  {/each}
</div>

<style>
  .checklist-container {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 8px;
    overflow-y: auto;
    padding: 12px 18px;
    box-sizing: border-box;
  }

  .checklist-container::-webkit-scrollbar {
    width: 4px;
  }

  .checklist-container::-webkit-scrollbar-thumb {
    background-color: rgba(44, 38, 34, 0.2);
    border-radius: 4px;
  }

  .checklist-row {
    display: flex;
    align-items: center;
    gap: 8px;
    transition: opacity 0.15s ease, transform 0.15s ease;
  }

  .checklist-row.dragging {
    opacity: 0.4;
    transform: scale(0.98);
  }

  .drag-handle {
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: grab;
    padding: 2px;
    opacity: 0.5;
    transition: opacity 0.15s ease;
  }

  .drag-handle:hover {
    opacity: 1;
  }

  .checklist-row.completed {
    opacity: 0.65;
  }

  .checklist-row.completed .item-input {
    text-decoration: line-through;
  }

  .checkbox-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-text-primary);
    padding: 2px;
    cursor: pointer;
    flex-shrink: 0;
  }

  .item-input {
    flex: 1;
    font-family: var(--font-note);
    font-size: 16px;
    line-height: 1.4;
    color: var(--color-text-primary);
    background: transparent;
    border: none;
    outline: none;
    padding: 2px 0;
  }

  .item-input::placeholder {
    color: rgba(44, 38, 34, 0.35);
  }
</style>
