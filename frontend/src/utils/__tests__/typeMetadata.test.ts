import { describe, it, expect } from 'vitest'
import { SECTION_TYPES, isSectionType, SECTION_META, getTypeLabel, getTypeBadgeClass } from '../typeMetadata'

describe('isSectionType', () => {
  it('returns true for section-like types', () => {
    const sectionTypes = ['chapter', 'section', 'appendix', 'part', 'preface',
      'dedication', 'acknowledgements', 'colophon', 'glossary',
      'bibliography', 'reference', 'refentry', 'procedure',
      'article', 'topic', 'set', 'index_block']

    for (const t of sectionTypes) {
      expect(isSectionType(t)).toBe(true)
    }
  })

  it('returns false for non-section types', () => {
    expect(isSectionType('paragraph')).toBe(false)
    expect(isSectionType('code_block')).toBe(false)
    expect(isSectionType('figure')).toBe(false)
    expect(isSectionType('table')).toBe(false)
    expect(isSectionType('admonition')).toBe(false)
  })
})

describe('SECTION_META', () => {
  it('defines metadata for all section types', () => {
    for (const type of SECTION_TYPES) {
      expect(SECTION_META[type]).toBeDefined()
    }
  })

  it('all entries have tag and headingTag', () => {
    for (const [type, meta] of Object.entries(SECTION_META)) {
      expect(meta.tag, `${type} should have tag`).toMatch(/^(section|article)$/)
      expect(meta.headingTag, `${type} should have headingTag`).toBeTruthy()
    }
  })

  it('chapter uses h1', () => {
    expect(SECTION_META.chapter.headingTag).toBe('h1')
  })

  it('section uses h2', () => {
    expect(SECTION_META.section.headingTag).toBe('h2')
  })

  it('refentry uses article tag', () => {
    expect(SECTION_META.refentry.tag).toBe('article')
    expect(SECTION_META.refentry.noAnchor).toBe(true)
    expect(SECTION_META.refentry.noNumbering).toBe(true)
  })

  it('dedication has contentWrapper', () => {
    expect(SECTION_META.dedication.contentWrapper).toBeDefined()
    expect(SECTION_META.dedication.contentWrapper?.class).toContain('text-center')
  })

  it('glossary uses dl wrapper', () => {
    expect(SECTION_META.glossary.contentWrapper?.tag).toBe('dl')
  })

  it('procedure uses ol wrapper', () => {
    expect(SECTION_META.procedure.contentWrapper?.tag).toBe('ol')
  })
})

describe('getTypeLabel', () => {
  it('returns non-empty for major types', () => {
    expect(getTypeLabel('part')).toBeTruthy()
    expect(getTypeLabel('chapter')).toBeTruthy()
    expect(getTypeLabel('appendix')).toBeTruthy()
  })

  it('returns empty for section', () => {
    expect(getTypeLabel('section')).toBe('')
  })
})

describe('getTypeBadgeClass', () => {
  it('returns badge-neutral for unknown', () => {
    expect(getTypeBadgeClass('foobar')).toBe('badge-neutral')
  })

  it('returns different classes for different types', () => {
    const classes = new Set([
      getTypeBadgeClass('chapter'),
      getTypeBadgeClass('part'),
      getTypeBadgeClass('appendix'),
    ])
    expect(classes.size).toBeGreaterThan(1)
  })
})
