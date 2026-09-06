<script lang="ts">
  interface Props {
    size?: number;
    color?: string;
  }
  let { size = 16, color = "currentColor" }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke={color} stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="7" cy="7" r="4.5" />
  <line x1="10.5" y1="10.5" x2="14" y2="14" />
</svg>
