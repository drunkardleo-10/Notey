<script lang="ts">
  import { onMount } from 'svelte';

  interface Props {
    value: string;
    onchange?: (val: string) => void;
  }

  interface NoteLine {
    id: string;
    isChecklist: boolean;
    isCompleted: boolean;
    text: string;
  }

  let { value = $bindable(''), onchange }: Props = $props();

  function parseMarkdown(md: string): NoteLine[] {
    if (!md || md.length === 0) {
      return [{
        id: `line-${Date.now()}-${Math.random()}`,
        isChecklist: false,
        isCompleted: false,
        text: '',
      }];
    }
    const rawLines = md.split('\n');
    return rawLines.map((raw, i) => {
      const match = raw.match(/^([-*]\s*\[([ xX]?)\]\s*)(.*)$/);
      if (match) {
        return {
          id: `line-${Date.now()}-${i}-${Math.random()}`,
          isChecklist: true,
          isCompleted: match[2].toLowerCase() === 'x',
          text: match[3],
        };
      }
      return {
        id: `line-${Date.now()}-${i}-${Math.random()}`,
        isChecklist: false,
        isCompleted: false,
        text: raw,
      };
    });
  }

  function serializeMarkdown(list: NoteLine[]): string {
    return list.map(item => {
      if (item.isChecklist) {
        return `- [${item.isCompleted ? 'x' : ' '}] ${item.text}`;
      }
      return item.text;
    }).join('\n');
  }

  let lines = $state<NoteLine[]>(parseMarkdown(value));
  let inputRefs = $state<(HTMLInputElement | null)[]>([]);
  let activeIndex = $state(0);
  let containerEl = $state<HTMLDivElement | null>(null);
  let lastSerialized = $state(value);

  $effect(() => {
    if (value !== lastSerialized) {
      lines = parseMarkdown(value);
      lastSerialized = value;
    }
  });

  function notify() {
    const serialized = serializeMarkdown(lines);
    lastSerialized = serialized;
    value = serialized;
    onchange?.(serialized);
  }

  export function toggleChecklist() {
    if (lines.length === 0) {
      lines = [{
        id: `line-${Date.now()}-${Math.random()}`,
        isChecklist: true,
        isCompleted: false,
        text: '',
      }];
      activeIndex = 0;
    } else {
      const idx = Math.min(Math.max(0, activeIndex), lines.length - 1);
      const line = lines[idx];
      if (line) {
        line.isChecklist = !line.isChecklist;
        if (!line.isChecklist) {
          line.isCompleted = false;
        }
      }
    }
    notify();
    requestAnimationFrame(() => {
      inputRefs[activeIndex]?.focus();
    });
  }

  function toggleCheck(index: number) {
    if (lines[index]) {
      lines[index].isCompleted = !lines[index].isCompleted;
      notify();
    }
  }

  function handleLineInput(index: number) {
    const line = lines[index];
    if (line && !line.isChecklist) {
      const match = line.text.match(/^([-*]\s*\[([ xX]?)\]\s*)(.*)$/);
      if (match) {
        line.isChecklist = true;
        line.isCompleted = match[2].toLowerCase() === 'x';
        line.text = match[3];
      }
    }
    notify();
  }

  function handleKeyDown(e: KeyboardEvent, index: number) {
    const input = inputRefs[index];
    const caretPos = input ? input.selectionStart ?? 0 : 0;
    const current = lines[index];

    if (e.key === 'Enter') {
      e.preventDefault();
      const before = current.text.slice(0, caretPos);
      const after = current.text.slice(caretPos);
      current.text = before;

      if (current.isChecklist) {
        if (current.text.trim().length === 0 && after.trim().length === 0) {
          current.isChecklist = false;
          current.isCompleted = false;
          notify();
          requestAnimationFrame(() => {
            inputRefs[index]?.focus();
          });
          return;
        }
        const newLine: NoteLine = {
          id: `line-${Date.now()}-${Math.random()}`,
          isChecklist: true,
          isCompleted: false,
          text: after,
        };
        lines.splice(index + 1, 0, newLine);
      } else {
        const newLine: NoteLine = {
          id: `line-${Date.now()}-${Math.random()}`,
          isChecklist: false,
          isCompleted: false,
          text: after,
        };
        lines.splice(index + 1, 0, newLine);
      }

      notify();
      const nextIdx = index + 1;
      activeIndex = nextIdx;
      requestAnimationFrame(() => {
        const nextInput = inputRefs[nextIdx];
        if (nextInput) {
          nextInput.focus();
          nextInput.setSelectionRange(0, 0);
        }
      });
    } else if (e.key === 'Backspace') {
      if (caretPos === 0 && input?.selectionEnd === 0) {
        if (current.isChecklist) {
          e.preventDefault();
          current.isChecklist = false;
          current.isCompleted = false;
          notify();
          requestAnimationFrame(() => {
            inputRefs[index]?.focus();
          });
        } else if (index > 0) {
          e.preventDefault();
          const prev = lines[index - 1];
          const prevLen = prev.text.length;
          prev.text += current.text;
          lines.splice(index, 1);
          notify();
          const prevIdx = index - 1;
          activeIndex = prevIdx;
          requestAnimationFrame(() => {
            const prevInput = inputRefs[prevIdx];
            if (prevInput) {
              prevInput.focus();
              prevInput.setSelectionRange(prevLen, prevLen);
            }
          });
        }
      }
    } else if (e.key === 'ArrowUp') {
      if (index > 0) {
        e.preventDefault();
        activeIndex = index - 1;
        const targetInput = inputRefs[index - 1];
        if (targetInput) {
          targetInput.focus();
          const targetPos = Math.min(caretPos, targetInput.value.length);
          targetInput.setSelectionRange(targetPos, targetPos);
        }
      }
    } else if (e.key === 'ArrowDown') {
      if (index < lines.length - 1) {
        e.preventDefault();
        activeIndex = index + 1;
        const targetInput = inputRefs[index + 1];
        if (targetInput) {
          targetInput.focus();
          const targetPos = Math.min(caretPos, targetInput.value.length);
          targetInput.setSelectionRange(targetPos, targetPos);
        }
      }
    } else if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'a') {
      if (input && input.selectionStart === 0 && input.selectionEnd === input.value.length && lines.length > 1) {
        e.preventDefault();
        navigator.clipboard.writeText(serializeMarkdown(lines));
      }
    }
  }

  function handleCopy(e: ClipboardEvent) {
    const input = document.activeElement as HTMLInputElement | null;
    if (input && input.selectionStart === 0 && input.selectionEnd === input.value.length && lines.length > 1) {
      e.preventDefault();
      e.clipboardData?.setData('text/plain', serializeMarkdown(lines));
    }
  }

  function handlePaste(e: ClipboardEvent, index: number) {
    const text = e.clipboardData?.getData('text/plain');
    if (!text || !text.includes('\n')) return;

    e.preventDefault();
    const splitLines = parseMarkdown(text);
    lines.splice(index, 1, ...splitLines);
    notify();
    const targetIdx = index + splitLines.length - 1;
    activeIndex = targetIdx;
    requestAnimationFrame(() => {
      inputRefs[targetIdx]?.focus();
    });
  }

  function handleContainerClick(e: MouseEvent) {
    if (e.target === containerEl) {
      const lastIdx = lines.length - 1;
      activeIndex = lastIdx;
      inputRefs[lastIdx]?.focus();
    }
  }

  onMount(() => {
    requestAnimationFrame(() => {
      inputRefs[0]?.focus();
    });
  });
</script>

<div
  class="note-body-editor"
  bind:this={containerEl}
  onclick={handleContainerClick}
  oncopy={handleCopy}
  role="presentation"
>
  {#each lines as line, index (line.id)}
    <div class="note-line" class:is-task={line.isChecklist}>
      {#if line.isChecklist}
        <button
          type="button"
          class="checkbox-box-btn"
          class:checked={line.isCompleted}
          onclick={() => toggleCheck(index)}
          tabindex="-1"
          aria-label={line.isCompleted ? "Mark incomplete" : "Mark complete"}
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            <rect
              x="2"
              y="2"
              width="16"
              height="16"
              rx="4.5"
              stroke="#2C2622"
              stroke-width="1.8"
              fill={line.isCompleted ? "#2C2622" : "rgba(255, 255, 255, 0.45)"}
            />
            {#if line.isCompleted}
              <path
                d="M5.5 10.5L8.5 13.5L14.5 7"
                stroke="#FDC844"
                stroke-width="2.2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            {/if}
          </svg>
        </button>
      {/if}

      <input
        type="text"
        class="line-input"
        class:completed-text={line.isChecklist && line.isCompleted}
        bind:value={line.text}
        bind:this={inputRefs[index]}
        oninput={() => handleLineInput(index)}
        onfocus={() => activeIndex = index}
        onkeydown={(e) => handleKeyDown(e, index)}
        onpaste={(e) => handlePaste(e, index)}
        placeholder={line.isChecklist ? "List item..." : (index === 0 && lines.length === 1 ? "Write a note..." : "")}
      />
    </div>
  {/each}
</div>

<style>
  .note-body-editor {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 3px;
    padding: 12px 18px 24px 18px;
    box-sizing: border-box;
    overflow-y: auto;
    overflow-x: hidden;
    cursor: text;
  }

  .note-body-editor::-webkit-scrollbar {
    width: 4px;
  }

  .note-body-editor::-webkit-scrollbar-thumb {
    background-color: rgba(44, 38, 34, 0.2);
    border-radius: 4px;
  }

  .note-line {
    display: flex;
    align-items: center;
    gap: 10px;
    min-height: 32px;
    width: 100%;
  }

  .checkbox-box-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
    cursor: pointer;
    flex-shrink: 0;
    border-radius: 5px;
    transition: transform 0.12s ease;
  }

  .checkbox-box-btn:hover {
    transform: scale(1.1);
  }

  .checkbox-box-btn:active {
    transform: scale(0.95);
  }

  .line-input {
    flex: 1;
    font-family: var(--font-note);
    font-size: 21px;
    font-weight: 500;
    font-style: normal;
    text-decoration: none;
    line-height: 1.35;
    color: var(--color-text-primary);
    background: transparent;
    border: none;
    outline: none;
    padding: 2px 0;
    margin: 0;
    width: 100%;
    min-width: 0;
  }

  .line-input::placeholder {
    color: rgba(44, 38, 34, 0.3);
    font-size: 19px;
  }

  .line-input.completed-text {
    text-decoration: line-through;
    opacity: 0.55;
  }
</style>
