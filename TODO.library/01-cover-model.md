# 01 — Cover Element Model

## Goal

Parse the DocBook `<cover>` element from `<info>` blocks and make cover image paths available to the output pipeline.

## Current State

The DocBook `<cover>` element (containing `<mediaobject>` with the cover image) exists in the DocBook 5 spec but is **completely ignored** by this codebase:

- `Info` model (`lib/docbook/elements/info.rb`) does not map `cover`
- `DocumentStats` (`lib/docbook/services/document_stats.rb`) does not extract cover
- Test fixtures in `spec/fixtures/xslTNG/test/resources/xml/book.014.xml` and `book.008.xml` contain `<cover>` elements — useful for validation

## Design

### OCP Compliance
Adding cover support should not modify any existing element classes except `Info`, which gains a new mapped attribute. All other consumers (stats, pipeline, formats) only **read** the cover — they don't change how Info works.

### Files

#### New: `lib/docbook/elements/cover.rb`

```ruby
# frozen_string_literal: true

module Docbook
  module Elements
    class Cover < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :mediaobject, MediaObject, collection: true

      xml do
        element "cover"
        mixed_content
        map_content to: :content
        map_element "mediaobject", to: :mediaobject
      end
    end
  end
end
```

Follows the same pattern as `LegalNotice` or `ReleaseInfo` — a simple element that wraps mixed content plus specific child elements.

#### Modify: `lib/docbook/elements.rb`

Add to autoload section (under Metadata elements):
```ruby
autoload :Cover, "#{__dir__}/elements/cover"
```

#### Modify: `lib/docbook/elements/info.rb`

Add attribute and mapping:
```ruby
attribute :cover, Cover, collection: true   # in attribute block
map_element "cover", to: :cover              # in xml block
```

#### Modify: `lib/docbook/services/document_stats.rb`

Add `extract_cover` private method:
```ruby
def extract_cover
  info = @document.info if @document.respond_to?(:info)
  return unless info&.cover && !info.cover.empty?

  first_cover = info.cover.first
  return unless first_cover.mediaobject && !first_cover.mediaobject.empty?

  first_media = first_cover.mediaobject.first
  return unless first_media.imageobject && !first_media.imageobject.empty?

  first_image = first_media.imageobject.first
  first_image.imagedata&.fileref
end
```

Add to `generate` method's returned hash:
```ruby
"cover" => extract_cover,
```

This follows the same pattern as `extract_title`, `extract_author`, etc.

## Verification

1. Parse `spec/fixtures/xslTNG/test/resources/xml/book.014.xml` and verify `info.cover.first.mediaobject` is populated
2. `DocumentStats.new(parsed).generate` returns a hash with `"cover"` key pointing to `"../media/yoyodyne.png"`
3. `bundle exec rspec` — all existing tests pass (zero behavior change for books without `<cover>`)
