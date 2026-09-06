import type { ChecklistItem } from '$lib/types';

export function markdownToChecklist(markdown: string): ChecklistItem[] {
  const lines = markdown.split('\n');
  const items: ChecklistItem[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const taskMatch = line.match(/^[-*]\s+\[([ xX])\]\s*(.*)$/);
    if (taskMatch) {
      items.push({
        id: `item-${i}-${Date.now()}`,
        text: taskMatch[2],
        isCompleted: taskMatch[1].toLowerCase() === 'x',
      });
      continue;
    }
    const bulletMatch = line.match(/^[-*+]\s+(.+)$/);
    if (bulletMatch) {
      items.push({
        id: `item-${i}-${Date.now()}`,
        text: bulletMatch[1],
        isCompleted: false,
      });
      continue;
    }
    const numberMatch = line.match(/^\d+[\.)]\s+(.+)$/);
    if (numberMatch) {
      items.push({
        id: `item-${i}-${Date.now()}`,
        text: numberMatch[1],
        isCompleted: false,
      });
      continue;
    }
    if (line.trim().length > 0) {
      items.push({
        id: `item-${i}-${Date.now()}`,
        text: line.trim(),
        isCompleted: false,
      });
    }
  }

  if (items.length === 0) {
    items.push({
      id: `item-0-${Date.now()}`,
      text: '',
      isCompleted: false,
    });
  }

  return items;
}

export function checklistToMarkdown(items: ChecklistItem[]): string {
  if (items.length === 1 && items[0].text.trim().length === 0) {
    return '';
  }
  return items
    .map((item) => `- [${item.isCompleted ? 'x' : ' '}] ${item.text}`)
    .join('\n');
}

export function checklistToPlainText(markdown: string): string {
  return markdown
    .split('\n')
    .map((line) => {
      const match = line.match(/^[-*]\s+\[([ xX])\]\s*(.*)$/);
      return match ? match[2] : line;
    })
    .join('\n');
}
