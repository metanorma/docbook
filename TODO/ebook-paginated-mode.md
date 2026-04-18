# E1 — Single page / paginated reading mode

**Tier:** 4 (nice-to-have)

## Description

Add a paginated reading mode where content is displayed one page at a time (like an ebook reader), instead of the current continuous scroll. Page breaks would be calculated based on viewport height and content width.

## Approach

- Calculate page boundaries based on viewport dimensions
- Support keyboard navigation (left/right arrows, space)
- Maintain scroll-position-based fallback for page calculation
- Allow toggling between scroll and page mode in settings
