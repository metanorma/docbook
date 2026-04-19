import type { MirrorBlockNode } from '@/stores/documentStore'

/**
 * Extract plain text content from a mirror block node tree.
 * Recursively walks the content array collecting text nodes.
 */
export function extractText(node: MirrorBlockNode): string {
  if (!node.content) return ''
  return node.content
    .filter((n): n is { type: 'text'; text: string } => n.type === 'text')
    .map(n => n.text)
    .join('')
}
