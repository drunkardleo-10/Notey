<script lang="ts">
  interface Props {
    size?: number;
    color?: string;
    filled?: boolean;
  }
  let { size = 16, color = "currentColor", filled = false }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 16 16" fill={filled ? color : "none"} stroke={color} stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12.5 7.5L8.5 3.5M10.5 2.5L13.5 5.5M4 9L7 12L6.5 13.5L2.5 9.5L4 9ZM8.5 3.5L5 7L2 8L8 14L9 11L12.5 7.5Z" />
  <line x1="2.5" y1="13.5" x2="1" y2="15" />
</svg>
