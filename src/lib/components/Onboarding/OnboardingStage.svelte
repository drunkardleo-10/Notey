<script lang="ts">
  import IconSearch from '$lib/components/Icons/IconSearch.svelte';

  interface Props {
    step: number;
  }

  let { step }: Props = $props();

  let isDemoFanned = $state(false);
</script>

<div class="onboarding-stage">
  {#if step === 1}
    <div class="stage-edge-simulation">
      <div class="peeking-tabs-column">
        <div class="demo-tab tab-yellow"></div>
        <div class="demo-tab tab-coral"></div>
        <div class="demo-tab tab-mint"></div>
        <div class="demo-tab tab-blue"></div>
      </div>
    </div>
  {:else if step === 2}
    <div
      class="stage-fan-simulation"
      onmouseenter={() => (isDemoFanned = true)}
      onmouseleave={() => (isDemoFanned = false)}
      role="region"
      aria-label="Interactive fan demo"
    >
      <div class="demo-fan-stack" class:fanned={isDemoFanned}>
        <div class="demo-card card-yellow">
          <span class="demo-card-title">Getting started</span>
          <span class="demo-card-body">Hover to fan your deck of notes</span>
        </div>
        <div class="demo-card card-coral">
          <span class="demo-card-title">Ideas</span>
          <span class="demo-card-body">Always on top across all Spaces</span>
        </div>
        <div class="demo-card card-mint">
          <span class="demo-card-title">Tasks</span>
          <span class="demo-card-body">No focus stealing</span>
        </div>
      </div>
      <div class="demo-hint">{isDemoFanned ? 'Hovering cards lifts them' : 'Move cursor here to fan'}</div>
    </div>
  {:else if step === 3}
    <div class="stage-editor-simulation">
      <div class="demo-editor-card">
        <div class="demo-editor-header">
          <div class="demo-dots">
            <span></span>
            <span></span>
          </div>
          <span class="demo-editor-title">Sprint retro</span>
          <span class="demo-saved">Saved · now</span>
        </div>
        <div class="demo-editor-content">
          Velocity was fine, review load was not. Rotate weekly.
        </div>
        <div class="demo-editor-toolbar">
          <div class="demo-swatches">
            <span class="d-swatch s-yellow active"></span>
            <span class="d-swatch s-coral"></span>
            <span class="d-swatch s-mint"></span>
            <span class="d-swatch s-blue"></span>
            <span class="d-swatch s-lavender"></span>
          </div>
          <span class="demo-pill">Close</span>
        </div>
      </div>
    </div>
  {:else if step === 4}
    <div class="stage-archive-simulation">
      <div class="demo-archive-window">
        <div class="demo-archive-list">
          <div class="demo-search-bar">
            <IconSearch size={11} color="#8C827A" />
            <span>Search</span>
          </div>
          <div class="demo-archive-item active">
            <span class="demo-stripe stripe-yellow"></span>
            <span>Q2 retro</span>
          </div>
          <div class="demo-archive-item">
            <span class="demo-stripe stripe-coral"></span>
            <span>Lisbon</span>
          </div>
          <div class="demo-archive-item">
            <span class="demo-stripe stripe-mint"></span>
            <span>Sourdough</span>
          </div>
        </div>
        <div class="demo-archive-card">
          <span class="demo-archive-card-title">Q2 retro notes</span>
          <p class="demo-archive-card-text">
            Velocity was fine, review load was not. Two people carried most reviews — rotate weekly.
          </p>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .onboarding-stage {
    width: 100%;
    height: 100%;
    border-radius: 18px;
    background: linear-gradient(135deg, var(--color-teal-start) 0%, var(--color-teal-end) 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
    user-select: none;
    padding: 20px;
  }

  .stage-edge-simulation {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: flex-end;
    align-items: center;
  }

  .peeking-tabs-column {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-right: -4px;
  }

  .demo-tab {
    width: 14px;
    height: 48px;
    border-radius: 6px 0 0 6px;
    box-shadow: -2px 2px 8px rgba(0, 0, 0, 0.25);
    transition: transform 0.2s ease;
  }

  .tab-yellow { background-color: var(--color-yellow); }
  .tab-coral { background-color: var(--color-coral); }
  .tab-mint { background-color: var(--color-mint); }
  .tab-blue { background-color: var(--color-blue); }

  .stage-fan-simulation {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    cursor: pointer;
  }

  .demo-fan-stack {
    position: relative;
    width: 220px;
    height: 160px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .demo-card {
    position: absolute;
    width: 170px;
    height: 110px;
    border-radius: 14px;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    box-shadow: -4px 8px 16px rgba(0, 0, 0, 0.25);
    transition: transform 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  .card-yellow {
    background-color: var(--color-yellow);
    transform: rotate(-6deg) translateY(-10px);
    z-index: 10;
  }

  .card-coral {
    background-color: var(--color-coral);
    transform: rotate(0deg);
    z-index: 20;
  }

  .card-mint {
    background-color: var(--color-mint);
    transform: rotate(6deg) translateY(10px);
    z-index: 30;
  }

  .demo-fan-stack.fanned .card-yellow {
    transform: rotate(-12deg) translate(-50px, -20px);
  }

  .demo-fan-stack.fanned .card-coral {
    transform: rotate(0deg) translateY(-5px) scale(1.05);
  }

  .demo-fan-stack.fanned .card-mint {
    transform: rotate(12deg) translate(50px, 20px);
  }

  .demo-card-title {
    font-family: var(--font-ui);
    font-size: 11px;
    font-weight: 700;
  }

  .demo-card-body {
    font-family: var(--font-note);
    font-size: 11px;
    line-height: 1.3;
  }

  .demo-hint {
    font-family: var(--font-ui);
    font-size: 11px;
    color: rgba(255, 255, 255, 0.7);
    margin-top: 14px;
  }

  .demo-editor-card {
    width: 260px;
    height: 180px;
    background-color: var(--color-yellow);
    border-radius: 16px;
    box-shadow: 0 12px 30px rgba(0, 0, 0, 0.3);
    display: flex;
    flex-direction: column;
    padding: 12px;
  }

  .demo-editor-header {
    display: flex;
    align-items: center;
    gap: 8px;
    border-bottom: 1px solid rgba(44, 38, 34, 0.1);
    padding-bottom: 6px;
  }

  .demo-dots {
    display: flex;
    gap: 4px;
  }

  .demo-dots span {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background-color: rgba(44, 38, 34, 0.2);
  }

  .demo-editor-title {
    font-family: var(--font-ui);
    font-size: 12px;
    font-weight: 700;
    flex: 1;
  }

  .demo-saved {
    font-family: var(--font-ui);
    font-size: 10px;
    color: rgba(44, 38, 34, 0.5);
  }

  .demo-editor-content {
    flex: 1;
    font-family: var(--font-note);
    font-size: 13px;
    line-height: 1.4;
    padding: 10px 0;
  }

  .demo-editor-toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid rgba(44, 38, 34, 0.08);
    padding-top: 6px;
  }

  .demo-swatches {
    display: flex;
    gap: 5px;
  }

  .d-swatch {
    width: 14px;
    height: 14px;
    border-radius: 4px;
  }

  .s-yellow { background-color: var(--color-yellow); }
  .s-coral { background-color: var(--color-coral); }
  .s-mint { background-color: var(--color-mint); }
  .s-blue { background-color: var(--color-blue); }
  .s-lavender { background-color: var(--color-lavender); }
  .d-swatch.active { box-shadow: 0 0 0 1.5px var(--color-text-primary); }

  .demo-pill {
    font-family: var(--font-ui);
    font-size: 10px;
    padding: 3px 8px;
    border-radius: 6px;
    border: 1px solid rgba(44, 38, 34, 0.2);
  }

  .demo-archive-window {
    width: 290px;
    height: 180px;
    background-color: var(--color-cream);
    border-radius: 14px;
    display: flex;
    box-shadow: 0 12px 30px rgba(0, 0, 0, 0.35);
    overflow: hidden;
  }

  .demo-archive-list {
    width: 110px;
    padding: 8px;
    border-right: 1px solid rgba(44, 38, 34, 0.08);
    display: flex;
    flex-direction: column;
    gap: 5px;
  }

  .demo-search-bar {
    display: flex;
    align-items: center;
    gap: 4px;
    background-color: rgba(44, 38, 34, 0.06);
    border-radius: 6px;
    padding: 4px 6px;
    font-family: var(--font-ui);
    font-size: 9px;
    color: var(--color-text-muted);
  }

  .demo-archive-item {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 4px 6px;
    border-radius: 6px;
    font-family: var(--font-ui);
    font-size: 10px;
    font-weight: 600;
  }

  .demo-archive-item.active {
    background-color: #E7E1D7;
  }

  .demo-stripe {
    width: 3px;
    height: 12px;
    border-radius: 2px;
  }

  .stripe-yellow { background-color: var(--color-yellow); }
  .stripe-coral { background-color: var(--color-coral); }
  .stripe-mint { background-color: var(--color-mint); }

  .demo-archive-card {
    flex: 1;
    margin: 8px;
    background-color: var(--color-yellow);
    border-radius: 10px;
    padding: 10px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
  }

  .demo-archive-card-title {
    font-family: var(--font-ui);
    font-size: 11px;
    font-weight: 700;
  }

  .demo-archive-card-text {
    font-family: var(--font-note);
    font-size: 10px;
    line-height: 1.3;
    margin: 0;
  }
</style>
