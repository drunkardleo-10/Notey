<script lang="ts">
  interface Props {
    size?: number;
    color?: string;
  }
  let { size = 16, color = "currentColor" }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke={color} stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <rect x="2" y="2.5" width="4.5" height="4.5" rx="1" />
  <path d="M3.2 4.8L4.2 5.8L6.2 3.8" />
  <line x1="9" y1="4.8" x2="14" y2="4.8" />
  <rect x="2" y="9.5" width="4.5" height="4.5" rx="1" />
  <line x1="9" y1="11.8" x2="14" y2="11.8" />
</svg>
