<script lang="ts">
  import type { NoteColor } from '$lib/types';

  interface Props {
    selected: NoteColor;
    onselect: (color: NoteColor) => void;
  }

  let { selected, onselect }: Props = $props();

  const swatches: { color: NoteColor; hex: string }[] = [
    { color: 'yellow', hex: '#FDC844' },
    { color: 'coral', hex: '#FF8A80' },
    { color: 'mint', hex: '#80E5D0' },
    { color: 'blue', hex: '#82B1FF' },
    { color: 'lavender', hex: '#CE93D8' },
  ];
</script>

<div class="swatch-picker" role="radiogroup" aria-label="Note color">
  {#each swatches as swatch}
    <button
      type="button"
      class="swatch-btn"
      class:active={selected === swatch.color}
      style="background-color: {swatch.hex};"
      onclick={() => onselect(swatch.color)}
      aria-checked={selected === swatch.color}
      role="radio"
      aria-label="{swatch.color} note color"
    ></button>
  {/each}
</div>

<style>
  .swatch-picker {
    display: flex;
    align-items: center;
    gap: 5px;
  }

  .swatch-btn {
    width: 17px;
    height: 17px;
    border-radius: 5px;
    border: 1.5px solid transparent;
    cursor: pointer;
    transition: transform 0.15s ease, box-shadow 0.15s ease;
  }

  .swatch-btn:hover {
    transform: scale(1.12);
  }

  .swatch-btn.active {
    box-shadow: 0 0 0 2px var(--color-text-primary);
    transform: scale(1.08);
  }
</style>
