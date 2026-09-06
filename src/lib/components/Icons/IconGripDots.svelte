<script lang="ts">
  interface Props {
    size?: number;
    color?: string;
  }
  let { size = 16, color = "currentColor" }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 16 16" fill={color}>
  <circle cx="5" cy="4" r="1.3" />
  <circle cx="11" cy="4" r="1.3" />
  <circle cx="5" cy="8" r="1.3" />
  <circle cx="11" cy="8" r="1.3" />
  <circle cx="5" cy="12" r="1.3" />
  <circle cx="11" cy="12" r="1.3" />
</svg>
