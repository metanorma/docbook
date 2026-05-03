import { describe, it, expect } from 'vitest'
import { findAncestorChain, getTypeLabel, getTypeBadgeClass } from '../breadcrumb'
import type { TocItem } from '@/stores/documentStore'

describe('findAncestorChain', () => {
  const tree: TocItem[] = [
    {
      id: 'ch1',
      title: 'Chapter 1',
      type: 'chapter',
      number: '1',
      children: [
        {
          id: 's1',
          title: 'Section 1',
          type: 'section',
          number: '1.1',
          children: [
            { id: 's1a', title: 'Section 1a', type: 'section', number: '1.1.1', children: [] },
          ],
        },
        { id: 's2', title: 'Section 2', type: 'section', number: '1.2', children: [] },
      ],
    },
    {
      id: 'ch2',
      title: 'Chapter 2',
      type: 'chapter',
      number: '2',
      children: [],
    },
  ]

  it('returns full ancestor chain for deep node', () => {
    const chain = findAncestorChain(tree, 's1a')
    expect(chain.map(n => n.id)).toEqual(['ch1', 's1', 's1a'])
  })

  it('returns chain for top-level node', () => {
    const chain = findAncestorChain(tree, 'ch1')
    expect(chain.map(n => n.id)).toEqual(['ch1'])
  })

  it('returns chain for second-level node', () => {
    const chain = findAncestorChain(tree, 's2')
    expect(chain.map(n => n.id)).toEqual(['ch1', 's2'])
  })

  it('returns empty array for non-existent ID', () => {
    const chain = findAncestorChain(tree, 'nonexistent')
    expect(chain).toEqual([])
  })

  it('works with empty tree', () => {
    const chain = findAncestorChain([], 'ch1')
    expect(chain).toEqual([])
  })

  it('finds in second root', () => {
    const chain = findAncestorChain(tree, 'ch2')
    expect(chain.map(n => n.id)).toEqual(['ch2'])
  })
})

describe('getTypeLabel', () => {
  it('returns correct labels for known types', () => {
    expect(getTypeLabel('chapter')).toBe('Ch')
    expect(getTypeLabel('part')).toBe('Pt')
    expect(getTypeLabel('appendix')).toBe('App')
    expect(getTypeLabel('glossary')).toBe('Gl')
    expect(getTypeLabel('bibliography')).toBe('Bib')
    expect(getTypeLabel('refentry')).toBe('p')
  })

  it('returns empty string for section and unknown', () => {
    expect(getTypeLabel('section')).toBe('')
    expect(getTypeLabel('unknown')).toBe('')
  })
})

describe('getTypeBadgeClass', () => {
  it('returns badge class for known types', () => {
    expect(getTypeBadgeClass('chapter')).toContain('badge-blue')
    expect(getTypeBadgeClass('part')).toContain('badge-purple')
    expect(getTypeBadgeClass('appendix')).toContain('badge-green')
  })

  it('returns neutral badge for unknown', () => {
    expect(getTypeBadgeClass('unknown')).toContain('badge-neutral')
  })

  it('refentry has mono badge', () => {
    expect(getTypeBadgeClass('refentry')).toContain('badge-mono')
  })
})
