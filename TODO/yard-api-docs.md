# R1 — Ruby API documentation (YARD)

**Tier:** 2 (medium)

## Problem

The gem has 170+ element classes, 7 service classes, 3 output classes, and various utilities. None of them have generated API documentation. The code has `@param` and `@return` tags in many places but they're not rendered anywhere.

## Approach

### 1. Add YARD gem dependency
```ruby
# In docbook.gemspec
spec.add_development_dependency 'yard', '~> 0.9'
```

### 2. Ensure all public methods have YARD tags
Key classes to document:
- `Docbook::Document` — `from_xml`, `supports?`
- `Docbook::Output::SinglePage` — constructor, `generate`
- `Docbook::Output::DocbookMirror` — `to_json`, `to_pretty_json`
- `Docbook::XIncludeResolver` — `resolve_string`
- `Docbook::XrefResolver`
- `Docbook::Services::ImageResolver` — `resolve`, strategies
- `Docbook::Services::TocGenerator` — `generate`
- `Docbook::Services::NumberingService` — `generate`
- `Docbook::Services::IndexCollector`, `IndexGenerator`

### 3. Add `.yardopts` file
```
--output-dir docs/api
--markup markdown
--no-private
lib/**/*.rb
```

### 4. Add Rake task
```ruby
require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--output-dir', 'docs/api', '--no-private']
end
```

### 5. Link from docs site
Add a link to the generated YARD docs from `docs/reference/index.adoc`.

## Verification

```bash
bundle exec rake yard
# Open docs/api/index.html in browser
```
