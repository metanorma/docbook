# D1 — Fix existing documentation issues

**Tier:** 1 (small, high value)

## Problems

### 1. Duplicate "Build an interactive reader" in INDEX.adoc
File: `docs/INDEX.adoc` lines 43-44

The "By Task" section has two identical entries. Remove the duplicate.

### 2. `--demo=NAME` syntax not documented
Files: `README.adoc`, `docs/interfaces/cli/build-command.adoc`

The CLI now supports `--demo=xslTNG` and `--demo=model-flow` but documentation still says:
```
--demo    Use the bundled DocBook sample as input
```

Should be:
```
--demo=NAME    Build a bundled demo (xslTNG or model-flow)
```

### 3. No documentation for `model-flow` demo
The `--demo=model-flow` option builds "The Art of the Model Flow" but there's no mention of it in docs.

### 4. Potential references to removed commands
Some doc files may reference `to-html` or `convert` commands that were removed during CLI cleanup. Audit all doc files for stale command references.

### 5. README homepage URL mismatch
`docbook.gemspec` says `https://github.com/metanorma/docbook` but README.adoc footer says `https://github.com/metanorma/metanorma-docbook`. Determine the correct URL and make them consistent.

## Tasks

1. Fix `docs/INDEX.adoc`: remove duplicate entry
2. Update `README.adoc`: document `--demo=NAME` syntax with examples
3. Update `docs/interfaces/cli/build-command.adoc`: document named demos
4. Audit all `docs/**/*.adoc` files for references to removed commands (`to-html`, `convert`)
5. Fix homepage URL consistency between gemspec and README
6. Add mention of model-flow demo in relevant docs

## Verification

```bash
grep -r "to-html\|convert" docs/
# Verify INDEX.adoc has no duplicate entries
# Verify --demo=NAME appears in README and build-command docs
```
