<script lang="ts">
  import IconPlus from '$lib/components/Icons/IconPlus.svelte';
  import IconGripDots from '$lib/components/Icons/IconGripDots.svelte';

  interface Props {
    isDeckHovered: boolean;
    onAddNote?: () => void;
  }

  let { isDeckHovered, onAddNote }: Props = $props();
</script>

<div
  class="edge-anchor"
  class:visible={isDeckHovered}
  class:hidden={!isDeckHovered}
>
  <button
    type="button"
    class="add-btn"
    onclick={onAddNote}
    aria-label="Add new note"
    tabindex={isDeckHovered ? 0 : -1}
  >
    <IconPlus size={15} color="#2C2622" />
  </button>

  <div class="grip-container" title="Deck anchor">
    <IconGripDots size={14} color="rgba(44, 38, 34, 0.45)" />
  </div>
</div>

<style>
  .edge-anchor {
    width: 34px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 0;
    margin: 0;
    user-select: none;
    transition: opacity 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
                transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  .edge-anchor.hidden {
    opacity: 0;
    pointer-events: none;
    transform: translateX(18px);
  }

  .edge-anchor.visible {
    opacity: 1;
    pointer-events: auto;
    transform: translateX(0);
  }

  .add-btn {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background-color: rgba(245, 239, 230, 0.95);
    border: 1px solid rgba(44, 38, 34, 0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 6px rgba(44, 38, 34, 0.15);
    cursor: pointer;
    transition: transform 0.18s ease, background-color 0.18s ease;
  }

  .add-btn:hover {
    transform: scale(1.1);
    background-color: #ffffff;
  }

  .add-btn:active {
    transform: scale(0.95);
  }

  .grip-container {
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    padding: 2px;
    transition: transform 0.18s ease;
  }

  .grip-container:hover {
    transform: scale(1.15);
  }
</style>
