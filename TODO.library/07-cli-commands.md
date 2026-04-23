# 07 — CLI Commands

## Goal

Update the `docbook build` command to accept `--format` and add a new `docbook library` command. Both share the same format and processing options.

## Design

### OCP Compliance
Adding a new format to the CLI requires only updating the `--format` option description. The command methods delegate to `Builder`/`LibraryBuilder`, which delegate to `Formats::FORMAT_MAP`. No command method changes needed.

### DRY
Both commands share option definitions and helper methods. Consider extracting shared options into a Thor concern or using `method_option` in a shared module.

## Files

### Modify: `lib/docbook/cli.rb`

#### Add shared format option

```ruby
# Add to both build and library commands:
option :format, default: "inline",
                desc: "Output format: inline (single HTML), dom (SEO HTML), dist (directory with JSON), paged (directory with page files)"
```

#### Update `build` command

```ruby
desc "build [INPUT]", "Build an interactive HTML reader from DocBook XML"
option :output, aliases: "-o", desc: "Output path (default: <input>.html)"
option :demo, desc: "Build a bundled demo: xslTNG or model-flow"
option :xinclude, type: :boolean, default: true
option :image_search_dir, type: :array, desc: "Directories to search for images"
option :image_strategy, default: "data_url", desc: "Image resolution: data_url, file_url, or relative"
option :sort_glossary, type: :boolean, default: false
option :title, desc: "Page title"
option :format, default: "inline", desc: "Output format: inline, dom, dist, paged"
def build(input = nil)
  # ... existing demo handling unchanged ...

  output_path = derive_output_path(input, options)
  format = options[:format].to_sym

  Docbook::Output::Builder.new(
    xml_path: xml_path,
    output_path: output_path,
    format: format,
    image_search_dirs: search_dirs,
    image_strategy: options[:image_strategy].to_sym,
    sort_glossary: options[:sort_glossary],
    title: title,
  ).build

  say "Built #{output_path} (format: #{format})"
end
```

#### Add `library` command

```ruby
desc "library INPUT", "Build a library HTML from a directory or manifest file"
option :output, aliases: "-o", desc: "Output path (default: library.html)"
option :title, desc: "Library title"
option :image_strategy, default: "data_url", desc: "Image resolution: data_url, file_url, or relative"
option :sort_glossary, type: :boolean, default: false
option :format, default: "inline", desc: "Output format: inline, dom, dist, paged"
def library(input)
  input_path = File.expand_path(input)
  raise FileNotFoundError, "Path not found: #{input_path}" unless File.exist?(input_path)

  output_path = File.expand_path(options[:output] || "library.html")
  format = options[:format].to_sym

  verbose_step("Scanning for books...")

  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  builder = Docbook::Output::LibraryBuilder.new(
    input_path: input_path,
    output_path: output_path,
    format: format,
    image_strategy: options[:image_strategy].to_sym,
    sort_glossary: options[:sort_glossary],
    title: options[:title],
  )

  builder.build

  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

  if verbose?
    stats = build_stats(output_path)
    verbose_step("  Completed in #{format_time(elapsed)}")
    verbose_step("  Output: #{output_path} (#{stats})")
  end

  say "Built library: #{output_path} (format: #{format})"
end
```

#### Derive output path

For `dist` and `paged` formats, the output is a directory, not a single file:

```ruby
def derive_output_path(input, options)
  if options[:format] == "dist" || options[:format] == "paged"
    options[:output] || File.join(Dir.pwd, File.basename(input, ".*"))
  else
    options[:output] || File.join(File.dirname(File.expand_path(input)), "#{File.basename(input, '.*')}.html")
  end
end
```

## CLI Usage Examples

```bash
# Single book — default format (inline)
docbook build book.xml

# Single book — SEO-friendly DOM
docbook build book.xml --format dom

# Single book — distribution directory with external JSON
docbook build book.xml --format dist -o mybook/

# Single book — paged, one HTML per chapter
docbook build book.xml --format paged -o mybook/

# Library from directory
docbook library my-books/ -o library.html

# Library from manifest, distribution mode
docbook library library.yml --format dist -o my-library/

# Library, paged mode (each book gets its own subdirectory)
docbook library my-books/ --format paged -o my-library/
```

## Verification

1. `docbook build spec/fixtures/kitchen-sink/kitchen-sink.xml` — default format (inline) works
2. `docbook build book.xml --format dom` — produces single HTML with pre-rendered content
3. `docbook build book.xml --format dist -o /tmp/mybook/` — produces directory with `index.html` + `data/`
4. `docbook build book.xml --format paged -o /tmp/mybook/` — produces directory with `pages/`
5. `docbook library spec/fixtures/library_sample/` — produces library HTML
6. `docbook help build` shows `--format` option
7. `docbook help library` shows all options
8. `bundle exec rspec` — no regressions
