<script lang="ts">
  import type { Note } from '$lib/types';

  interface Props {
    note: Note;
    index: number;
    total: number;
    onSelect?: (note: Note) => void;
  }

  let { note, index, total, onSelect }: Props = $props();

  let rotationAngle = $derived.by(() => {
    if (total <= 1) return 0;
    const step = 8 / (total - 1);
    return -4 + index * step;
  });

  let xOffset = $derived.by(() => {
    return Math.abs(index - (total - 1) / 2) * 6;
  });

  let tabLabel = $derived(note.title.trim().split(' ')[0].toUpperCase() || 'NOTE');
</script>

<button
  type="button"
  class="fanned-card"
  style="
    background-color: var(--color-{note.color});
    --rot: {rotationAngle}deg;
    --x-off: {xOffset}px;
    z-index: {10 + index};
  "
  onclick={() => onSelect?.(note)}
  aria-label={note.title}
>
  <div class="card-tab-edge">
    <span class="vertical-label">{tabLabel}</span>
    <div class="perforation-divider"></div>
  </div>

  <div class="card-content">
    <h3 class="card-title">{note.title}</h3>
    <p class="card-body-preview">{note.body}</p>
  </div>
</button>

<style>
  .fanned-card {
    position: relative;
    width: 320px;
    min-height: 180px;
    border-radius: 20px;
    display: flex;
    box-shadow: -4px 8px 20px rgba(44, 38, 34, 0.16);
    cursor: pointer;
    transform: rotate(var(--rot)) translateX(calc(-1 * var(--x-off)));
    transition: transform 0.28s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.28s ease;
    user-select: none;
    outline: none;
    overflow: hidden;
    text-align: left;
    border: none;
    padding: 0;
  }

  .fanned-card:hover {
    transform: scale(1.04) translateX(-12px) rotate(0deg);
    box-shadow: -8px 14px 28px rgba(44, 38, 34, 0.22);
    z-index: 60 !important;
  }

  .card-tab-edge {
    position: relative;
    width: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .vertical-label {
    writing-mode: vertical-rl;
    transform: rotate(180deg);
    font-family: var(--font-ui);
    font-size: 10px;
    font-weight: 800;
    letter-spacing: 0.12em;
    color: rgba(44, 38, 34, 0.65);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-height: 140px;
  }

  .perforation-divider {
    position: absolute;
    right: 0;
    top: 6px;
    bottom: 6px;
    width: 1px;
    border-right: 1.5px dashed rgba(44, 38, 34, 0.22);
  }

  .card-content {
    flex: 1;
    padding: 16px 16px 16px 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    overflow: hidden;
  }

  .card-title {
    font-family: var(--font-ui);
    font-size: 15px;
    font-weight: 700;
    color: var(--color-text-primary);
    line-height: 1.2;
    margin: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .card-body-preview {
    font-family: var(--font-note);
    font-size: 14px;
    line-height: 1.4;
    color: var(--color-text-primary);
    margin: 0;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 5;
    line-clamp: 5;
    -webkit-box-orient: vertical;
    word-break: break-word;
  }
</style>
