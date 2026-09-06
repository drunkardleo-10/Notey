<script lang="ts">
  interface Props {
    size?: number;
    color?: string;
  }
  let { size = 16, color = "currentColor" }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke={color} stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <line x1="8" y1="3" x2="8" y2="13" />
  <line x1="3" y1="8" x2="13" y2="8" />
</svg>
