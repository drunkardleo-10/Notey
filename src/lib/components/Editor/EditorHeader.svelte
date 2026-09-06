<script lang="ts">
  import IconGripDots from '$lib/components/Icons/IconGripDots.svelte';
  import IconPushpin from '$lib/components/Icons/IconPushpin.svelte';

  interface Props {
    title: string;
    isPinned: boolean;
    autosaveStatus: string;
    ontitlechange?: (title: string) => void;
    ontogglepin?: () => void;
    onclose?: () => void;
    ondragstart?: (e: PointerEvent) => void;
  }

  let { title = $bindable(), isPinned, autosaveStatus, ontitlechange, ontogglepin, onclose, ondragstart }: Props = $props();

  function handleInput(e: Event) {
    const target = e.target as HTMLInputElement;
    title = target.value;
    ontitlechange?.(target.value);
  }
</script>

<header class="editor-header">
  <div class="header-left">
    <div class="dot-indicators">
      <button
        type="button"
        class="native-close-btn"
        onclick={() => onclose?.()}
        aria-label="Close note"
        title="Close note"
      >
        <svg class="close-cross-icon" width="6" height="6" viewBox="0 0 6 6" fill="none">
          <path d="M1 1L5 5M5 1L1 5" stroke="#4C0000" stroke-width="1.2" stroke-linecap="round" />
        </svg>
      </button>
    </div>
    <input
      type="text"
      class="title-input"
      value={title}
      placeholder="Untitled note"
      oninput={handleInput}
    />
  </div>

  <div class="header-right">
    <span class="autosave-label">{autosaveStatus}</span>
    <div
      class="grip-handle"
      role="button"
      tabindex="0"
      onpointerdown={ondragstart}
      title="Drag note"
      aria-label="Drag note"
    >
      <IconGripDots size={14} color="rgba(44, 38, 34, 0.4)" />
    </div>
    <button
      type="button"
      class="pin-btn"
      class:pinned={isPinned}
      onclick={ontogglepin}
      aria-label={isPinned ? "Unpin note" : "Pin note"}
    >
      <IconPushpin size={15} color="#2C2622" filled={isPinned} />
    </button>
  </div>
</header>
<div class="header-divider"></div>

<style>
  .editor-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px 8px 16px;
    gap: 12px;
    user-select: none;
  }

  .header-left {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: 1;
    min-width: 0;
  }

  .dot-indicators {
    display: flex;
    gap: 5px;
    align-items: center;
    flex-shrink: 0;
  }

  .native-close-btn {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background-color: #FF5F56;
    border: 0.5px solid rgba(0, 0, 0, 0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    padding: 0;
    margin: 0;
    outline: none;
    transition: filter 0.15s ease, transform 0.12s ease;
  }

  .native-close-btn:hover {
    filter: brightness(0.92);
    transform: scale(1.08);
  }

  .native-close-btn:active {
    filter: brightness(0.82);
    transform: scale(0.95);
  }

  .close-cross-icon {
    opacity: 0;
    transition: opacity 0.12s ease;
  }

  .native-close-btn:hover .close-cross-icon {
    opacity: 0.75;
  }

  .title-input {
    font-family: var(--font-ui);
    font-size: 15px;
    font-weight: 700;
    color: var(--color-text-primary);
    background: transparent;
    border: none;
    outline: none;
    width: 100%;
    min-width: 0;
    padding: 2px 0;
    text-overflow: ellipsis;
  }

  .title-input::placeholder {
    color: rgba(44, 38, 34, 0.35);
  }

  .header-right {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .autosave-label {
    font-family: var(--font-ui);
    font-size: 11px;
    color: rgba(44, 38, 34, 0.5);
    white-space: nowrap;
  }

  .grip-handle {
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: grab;
    padding: 3px 4px;
    border-radius: 4px;
    transition: background-color 0.15s ease;
    user-select: none;
    -webkit-user-select: none;
  }

  .grip-handle:hover {
    background-color: rgba(44, 38, 34, 0.08);
  }

  .grip-handle:active {
    cursor: grabbing;
  }

  .pin-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2px;
    cursor: pointer;
    transition: transform 0.15s ease;
    opacity: 0.65;
  }

  .pin-btn:hover {
    transform: scale(1.1);
    opacity: 1;
  }

  .pin-btn.pinned {
    opacity: 1;
  }

  .header-divider {
    height: 1px;
    width: 100%;
    background-color: rgba(44, 38, 34, 0.08);
  }
</style>
