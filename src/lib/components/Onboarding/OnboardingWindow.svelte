<script lang="ts">
  import OnboardingStage from './OnboardingStage.svelte';

  interface Props {
    oncomplete: (addToLogin: boolean) => void;
    onskip: () => void;
  }

  let { oncomplete, onskip }: Props = $props();

  let currentStep = $state(1);
  let addToLogin = $state(true);

  const stepsData = [
    {
      step: 1,
      title: 'Your notes wait at the edge',
      body: 'A thin strip on the right edge of your screen is all you see. Each stripe is a note, in its own color, so you can tell what is there at a glance.',
      badgeText: 'Nothing to click',
      badgeDesc: 'the pill sits out of the way until you need it',
    },
    {
      step: 2,
      title: 'Hover the edge to fan',
      body: 'Moving your cursor to the edge slides the notes out into a fanned stack. Hover any note to inspect its full text without clicking.',
      badgeText: 'Hover to fan',
      badgeDesc: 'cards lift and expand for preview reading',
    },
    {
      step: 3,
      title: 'Fast, flexible sticky editor',
      body: 'Click any card to open the editor. Change colors, switch to interactive checklist mode, pin notes, and enjoy automatic background saving.',
      badgeText: 'Autosaved',
      badgeDesc: 'changes save quietly in the background',
    },
    {
      step: 4,
      title: 'Archive what you are done with',
      body: 'Archived notes leave the deck but are kept. Search the archive by title or by anything written inside a note, then restore it to the deck in one click.',
      badgeText: '⌥⌘L',
      badgeDesc: 'opens the archive',
    },
  ];

  let currentData = $derived(stepsData[currentStep - 1]);

  function handleNext() {
    if (currentStep < 4) {
      currentStep++;
    } else {
      oncomplete(addToLogin);
    }
  }
</script>

<div class="onboarding-window" role="dialog" aria-label="Onboarding tour">
  <div class="onboarding-left">
    <div class="traffic-lights">
      <span class="traffic-dot close-dot"></span>
      <span class="traffic-dot min-dot"></span>
      <span class="traffic-dot max-dot"></span>
    </div>

    <div class="step-label">STEP {currentStep} OF 4</div>

    <h1 class="step-title">{currentData.title}</h1>

    <p class="step-body">{currentData.body}</p>

    <div class="badge-card">
      <span class="pill-badge">{currentData.badgeText}</span>
      <span class="pill-desc">{currentData.badgeDesc}</span>
    </div>

    {#if currentStep === 4}
      <label class="login-item-card">
        <input
          type="checkbox"
          class="login-checkbox"
          bind:checked={addToLogin}
        />
        <span class="login-label">
          <strong>Add to Login Items</strong> — open automatically at sign-in
        </span>
      </label>
    {/if}

    <div class="left-spacer"></div>

    <footer class="onboarding-footer">
      <div class="step-dots">
        {#each [1, 2, 3, 4] as s}
          <span class="dot" class:active-pill={currentStep === s}></span>
        {/each}
      </div>

      <div class="footer-actions">
        {#if currentStep < 4}
          <button type="button" class="btn-skip" onclick={onskip}>
            Skip
          </button>
        {/if}
        <button type="button" class="btn-primary" onclick={handleNext}>
          {currentStep === 4 ? 'Create my first note' : 'Continue'}
        </button>
      </div>
    </footer>
  </div>

  <div class="onboarding-right">
    <OnboardingStage step={currentStep} />
  </div>
</div>

<style>
  .onboarding-window {
    width: 740px;
    height: 460px;
    border-radius: 20px;
    background-color: var(--color-cream);
    display: flex;
    box-shadow: 0 24px 60px rgba(44, 38, 34, 0.32);
    overflow: hidden;
    user-select: none;
    border: 1px solid rgba(44, 38, 34, 0.12);
  }

  .onboarding-left {
    width: 320px;
    padding: 24px 28px;
    display: flex;
    flex-direction: column;
    background-color: var(--color-cream);
  }

  .traffic-lights {
    display: flex;
    gap: 7px;
    margin-bottom: 24px;
  }

  .traffic-dot {
    width: 11px;
    height: 11px;
    border-radius: 50%;
  }

  .close-dot { background-color: #FF5F56; }
  .min-dot { background-color: #FFBD2E; }
  .max-dot { background-color: #27C93F; }

  .step-label {
    font-family: var(--font-ui);
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.12em;
    color: var(--color-text-muted);
    margin-bottom: 8px;
  }

  .step-title {
    font-family: var(--font-ui);
    font-size: 22px;
    font-weight: 800;
    line-height: 1.2;
    color: var(--color-text-primary);
    margin: 0 0 14px 0;
    letter-spacing: -0.02em;
  }

  .step-body {
    font-family: var(--font-ui);
    font-size: 13px;
    line-height: 1.5;
    color: rgba(44, 38, 34, 0.75);
    margin: 0 0 18px 0;
  }

  .badge-card {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 16px;
  }

  .pill-badge {
    font-family: var(--font-ui);
    font-size: 11px;
    font-weight: 700;
    background-color: rgba(44, 38, 34, 0.08);
    color: var(--color-text-primary);
    padding: 5px 10px;
    border-radius: 8px;
    white-space: nowrap;
  }

  .pill-desc {
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--color-text-muted);
    line-height: 1.3;
  }

  .login-item-card {
    display: flex;
    align-items: center;
    gap: 10px;
    background-color: rgba(44, 38, 34, 0.06);
    border-radius: 12px;
    padding: 12px 14px;
    cursor: pointer;
    margin-bottom: 12px;
  }

  .login-checkbox {
    width: 16px;
    height: 16px;
    accent-color: var(--color-yellow);
    cursor: pointer;
  }

  .login-label {
    font-family: var(--font-ui);
    font-size: 12px;
    color: var(--color-text-primary);
    line-height: 1.3;
  }

  .left-spacer {
    flex: 1;
  }

  .onboarding-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 12px;
  }

  .step-dots {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background-color: rgba(44, 38, 34, 0.2);
    transition: all 0.25s ease;
  }

  .dot.active-pill {
    width: 20px;
    border-radius: 4px;
    background-color: rgba(44, 38, 34, 0.7);
  }

  .footer-actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .btn-skip {
    font-family: var(--font-ui);
    font-size: 13px;
    font-weight: 600;
    color: var(--color-text-muted);
    cursor: pointer;
    transition: color 0.15s ease;
  }

  .btn-skip:hover {
    color: var(--color-text-primary);
  }

  .btn-primary {
    font-family: var(--font-ui);
    font-size: 13px;
    font-weight: 700;
    background-color: var(--color-yellow);
    color: var(--color-text-primary);
    padding: 9px 18px;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(253, 200, 68, 0.35);
    cursor: pointer;
    transition: transform 0.15s ease, opacity 0.15s ease;
  }

  .btn-primary:hover {
    opacity: 0.92;
    transform: translateY(-1px);
  }

  .btn-primary:active {
    transform: translateY(0);
  }

  .onboarding-right {
    flex: 1;
    padding: 14px 14px 14px 0;
  }
</style>
