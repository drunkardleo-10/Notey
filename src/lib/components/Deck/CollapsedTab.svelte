<script lang="ts">
  import type { Note } from '$lib/types';

  interface Props {
    note: Note;
    isDeckHovered: boolean;
    isCardExpanded: boolean;
    onSelect?: (note: Note) => void;
    onHover?: () => void;
    onLeave?: () => void;
  }

  let {
    note,
    isDeckHovered,
    isCardExpanded,
    onSelect,
    onHover,
    onLeave
  }: Props = $props();

  let tabLabel = $derived(note.title.trim().split(' ')[0].toUpperCase() || 'NOTE');

  interface PreviewLine {
    isTask: boolean;
    isCompleted: boolean;
    text: string;
  }

  let previewLines = $derived.by<PreviewLine[]>(() => {
    if (!note.body) return [];
    const rawLines = note.body.split('\n');
    const result: PreviewLine[] = [];

    for (const rawLine of rawLines) {
      const segments = rawLine.split(/(?=(?:^|\s)[-*]\s*\[[ xX]?\])/g);
      for (let segment of segments) {
        segment = segment.trim();
        if (!segment) continue;
        const match = segment.match(/^[-*]\s*\[([ xX]?)\]\s*(.*)$/);
        if (match) {
          result.push({
            isTask: true,
            isCompleted: match[1].toLowerCase() === 'x',
            text: match[2].trim(),
          });
        } else {
          result.push({
            isTask: false,
            isCompleted: false,
            text: segment,
          });
        }
      }
    }
    return result;
  });
</script>

<button
  type="button"
  class="collapsed-tab"
  class:idle={!isDeckHovered}
  class:peeking={isDeckHovered && !isCardExpanded}
  class:expanded={isCardExpanded}
  style="background-color: var(--color-{note.color});"
  onclick={() => onSelect?.(note)}
  onmouseenter={onHover}
  onmouseleave={onLeave}
  aria-label={note.title}
>
  <div class="tab-handle">
    <span class="vertical-label">{tabLabel}</span>
    <div class="perforation-divider"></div>
  </div>

  {#if isCardExpanded}
    <div class="card-preview-body">
      <h3 class="card-title">{note.title}</h3>
      <div class="card-lines-list">
        {#each previewLines as line}
          <div class="card-line" class:completed-line={line.isCompleted}>
            {#if line.isTask}
              <svg class="card-checkbox-icon" width="14" height="14" viewBox="0 0 14 14" fill="none">
                <rect
                  x="1"
                  y="1"
                  width="12"
                  height="12"
                  rx="3.2"
                  stroke="#2C2622"
                  stroke-width="1.6"
                  fill={line.isCompleted ? "#2C2622" : "none"}
                />
                {#if line.isCompleted}
                  <path
                    d="M3.5 7L5.8 9.3L10.5 4.5"
                    stroke="#FDC844"
                    stroke-width="1.8"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                {/if}
              </svg>
            {/if}
            <span class="card-line-text">{line.text}</span>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</button>

<style>
  .collapsed-tab {
    position: relative;
    display: flex;
    align-items: stretch;
    justify-content: flex-start;
    outline: none;
    border: none;
    padding: 0;
    margin: 0;
    cursor: pointer;
    user-select: none;
    text-align: left;
    overflow: hidden;
    align-self: flex-end;
    transition: width 0.26s cubic-bezier(0.16, 1, 0.3, 1),
                height 0.26s cubic-bezier(0.16, 1, 0.3, 1),
                border-radius 0.2s ease,
                box-shadow 0.2s ease;
  }

  .collapsed-tab.idle {
    width: 6px;
    height: 32px;
    border-radius: 5px 0 0 5px;
    box-shadow: -1px 1px 3px rgba(44, 38, 34, 0.2);
  }

  .collapsed-tab.peeking {
    width: 34px;
    height: 74px;
    border-radius: 14px 0 0 14px;
    box-shadow: -2px 3px 8px rgba(44, 38, 34, 0.16);
  }

  .collapsed-tab.expanded {
    width: 195px;
    height: 150px;
    border-radius: 18px 0 0 18px;
    box-shadow: -5px 8px 24px rgba(44, 38, 34, 0.24);
    z-index: 50;
  }

  .tab-handle {
    position: relative;
    width: 34px;
    height: 100%;
    display: flex;
    align-items: flex-start;
    justify-content: center;
    padding-top: 14px;
    flex-shrink: 0;
  }

  .collapsed-tab.idle .tab-handle {
    opacity: 0;
    pointer-events: none;
  }

  .vertical-label {
    writing-mode: vertical-rl;
    font-family: var(--font-ui);
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.12em;
    color: rgba(44, 38, 34, 0.75);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-height: 80px;
    opacity: 0;
    transition: opacity 0.15s ease;
  }

  .collapsed-tab.peeking .vertical-label,
  .collapsed-tab.expanded .vertical-label {
    opacity: 1;
  }

  .perforation-divider {
    position: absolute;
    right: 0;
    top: 0;
    bottom: 0;
    width: 1px;
    border-right: 1.5px dashed rgba(44, 38, 34, 0.22);
    opacity: 0;
    transition: opacity 0.15s ease;
  }

  .collapsed-tab.peeking .perforation-divider,
  .collapsed-tab.expanded .perforation-divider {
    opacity: 1;
  }

  .card-preview-body {
    flex: 1;
    height: 100%;
    padding: 12px 14px 12px 12px;
    display: flex;
    flex-direction: column;
    gap: 6px;
    overflow: hidden;
    min-width: 0;
    animation: previewIn 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .card-title {
    font-family: var(--font-ui);
    font-size: 16px;
    font-weight: 800;
    color: var(--color-text-primary);
    line-height: 1.2;
    margin: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .card-lines-list {
    display: flex;
    flex-direction: column;
    gap: 5px;
    overflow: hidden;
    flex: 1;
  }

  .card-line {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 20px;
    line-height: 1.25;
  }

  .card-checkbox-icon {
    flex-shrink: 0;
    display: block;
  }

  .card-line-text {
    font-family: var(--font-note);
    font-size: 17px;
    font-weight: 700;
    font-style: normal;
    color: var(--color-text-primary);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .card-line.completed-line .card-line-text {
    text-decoration: line-through;
    opacity: 0.55;
  }

  @keyframes previewIn {
    from {
      opacity: 0;
      transform: translateX(10px);
    }
    to {
      opacity: 1;
      transform: translateX(0);
    }
  }
</style>
