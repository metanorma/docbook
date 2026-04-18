# R4 — Q&A set processing

**Tier:** 2 (medium)

## Problem

DocBook `<qandaset>` structures are used for FAQ-style content:

```xml
<qandaset>
  <qandaentry>
    <question><para>What is X?</para></question>
    <answer><para>X is Y.</para></answer>
  </qandaentry>
</qandaset>
```

XSLT renders these with visual distinction between questions and answers. This is not yet implemented.

## What To Do

1. **Transformer** — add `qandaset_node`, `qandaentry_node`, `question_node`, `answer_node` handlers
2. **Frontend** — render qandaset as a styled FAQ block with question/answer formatting
3. **Optional** — add collapsible accordion for each question

## Files

- `lib/docbook/mirror/transformer.rb` — qandaset node handlers
- `frontend/src/components/MirrorRenderer.vue` — qandaset rendering

## Verification

Build a DocBook fixture with `<qandaset>` elements and verify questions and answers render distinctly.
