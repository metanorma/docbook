# R3 — Callout markers for code

**Tier:** 2 (medium)

## Problem

DocBook supports callout markers in code blocks for line-by-line annotations:

```xml
<programlisting><co xml:id="co1"/>some code</programlisting>
<calloutlist>
  <callout arearef="co1"><para>Description</para></callout>
</calloutlist>
```

The XSLT stylesheets render these as numbered markers inline in the code, with a corresponding numbered list below. This is not yet implemented.

## What To Do

1. **Transformer** — handle `<co>` elements as inline numbered markers in code blocks
2. **Transformer** — handle `<calloutlist>` / `<callout>` as a numbered annotation list
3. **Frontend** — render callout markers as styled inline badges in code blocks
4. **Frontend** — render calloutlist as a visually distinct annotation list

## Files

- `lib/docbook/mirror/transformer.rb` — `co` and `calloutlist` node handlers
- `frontend/src/components/MirrorRenderer.vue` — calloutlist rendering
- `frontend/src/components/TextRenderer.vue` — co marker rendering

## Verification

Build a DocBook fixture with `<co>` and `<calloutlist>` elements and verify numbered markers appear in code with matching descriptions below.
