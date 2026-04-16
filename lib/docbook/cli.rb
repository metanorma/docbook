# frozen_string_literal: true

require "thor"
require "nokogiri"
require "fileutils"

module Docbook
  class CLI < Thor
    # ---- Primary commands (user-facing) ----

    desc "build INPUT", "Build an interactive HTML reader from DocBook XML"
    option :output, aliases: "-o", required: true, desc: "Output HTML file path"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    option :image_search_dir, type: :array, desc: "Directories to search for images"
    option :image_strategy, default: "data_url", desc: "Image resolution: data_url, file_url, or relative"
    option :title, desc: "Page title (default: derived from document)"
    def build(input)
      xml_path = File.expand_path(input)
      output_path = File.expand_path(options[:output])

      search_dirs = (options[:image_search_dir] || []).map { |d| File.expand_path(d) }
      search_dirs << File.dirname(xml_path) if search_dirs.empty?

      page = Docbook::Output::SinglePage.new(
        xml_path: xml_path,
        output_path: output_path,
        image_search_dirs: search_dirs,
        image_strategy: options[:image_strategy].to_sym,
        title: options[:title] || File.basename(xml_path, ".xml")
      )

      page.generate
      puts "Built #{output_path}"
    end

    desc "convert INPUT", "Convert DocBook XML to static HTML"
    option :output, aliases: "-o", desc: "Output file or directory"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    option :output_type, default: :single_file, desc: "Output type: single_file or directory"
    def convert(input)
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      xref_resolver = Docbook::XrefResolver.new(parsed).resolve!
      base_path = File.dirname(File.expand_path(input))
      output_mode = options[:output_type].to_sym
      output_path = if output_mode == :directory && options[:output]
                      File.expand_path(options[:output])
                    elsif output_mode == :single_file && options[:output]
                      File.dirname(File.expand_path(options[:output]))
                    end

      html = Docbook::Output::Html.new(
        parsed,
        xref_resolver: xref_resolver,
        output_mode: output_mode,
        base_path: base_path,
        output_path: output_path
      ).to_html

      write_output(html, options[:output], output_mode)
    end

    desc "export INPUT", "Export DocBook XML as DocbookMirror JSON"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :pretty, type: :boolean, default: true, desc: "Pretty print JSON"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    def export(input)
      require_relative "mirror"
      require_relative "output/docbook_mirror"
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      mirror_output = Docbook::Output::DocbookMirror.new(parsed)
      output = if options[:pretty]
                 mirror_output.to_pretty_json
               else
                 mirror_output.to_json
               end
      if options[:output]
        File.write(options[:output], output)
        puts "Written to #{options[:output]}"
      else
        $stdout.write(output)
      end
    end

    desc "validate INPUT", "Validate DocBook XML"
    option :schema, type: :boolean, default: true, desc: "Validate against DocBook 5 RELAX NG schema"
    option :wellformed, type: :boolean, default: false, desc: "Check well-formedness only (no schema)"
    def validate(input)
      xml_string = File.read(input)
      doc = Nokogiri::XML(xml_string)

      if doc.errors.any?
        doc.errors.each { |e| warn "#{input}: #{e}" }
        exit 1
      end

      if options[:schema] && !options[:wellformed]
        errors = validate_schema(doc, input)
        if errors.any?
          errors.each { |e| warn "#{input}: #{e}" }
          exit 1
        end
      end

      puts "#{input}: valid"
    end

    desc "format INPUT", "Format/prettify DocBook XML"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :xinclude, type: :boolean, default: false, desc: "Resolve XIncludes before processing"
    def format(input)
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      output = parsed.to_xml(pretty: true, declaration: true, encoding: "utf-8")
      write_output(output, options[:output], :single_file)
    end

    desc "demo", "Build a demo reader from the bundled DocBook sample"
    option :output, aliases: "-o", default: "demo.html", desc: "Output HTML file path"
    def demo
      fixture_xml = File.expand_path("../../spec/fixtures/xslTNG/guide/xml/guide.xml", __dir__)
      media_dir = File.expand_path("../../spec/fixtures/xslTNG/guide/resources/media", __dir__)
      output_path = File.expand_path(options[:output])

      abort "Demo fixture not found: #{fixture_xml}" unless File.exist?(fixture_xml)

      page = Docbook::Output::SinglePage.new(
        xml_path: fixture_xml,
        output_path: output_path,
        image_search_dirs: [media_dir],
        image_strategy: :data_url,
        title: "DocBook XSLT 2.0 Stylesheet Reference"
      )

      page.generate
      puts "Built demo at #{output_path}"
    end

    # ---- Development commands ----

    desc "roundtrip INPUT...", "Round-trip test DocBook XML files"
    def roundtrip(*inputs)
      failures = 0
      inputs.each do |input|
        xml_string = File.read(input)
        begin
          parsed = parse_input(xml_string)
          output = parsed.to_xml(declaration: true, encoding: "utf-8")
          parse_input(output)
          puts "#{input}: OK"
        rescue StandardError => e
          warn "#{input}: FAIL - #{e.message}"
          failures += 1
        end
      end
      warn "#{inputs.size} files, #{failures} failures"
      exit 1 if failures.positive?
    end

    # ---- Backward-compatible aliases (hidden) ----
    # These map the old command names to the new ones.

    desc "to-html INPUT", "Alias for 'convert'", hide: true
    option :output, aliases: "-o", desc: "Output file or directory"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes"
    option :output_type, default: :single_file, desc: "Output type"
    def to_html(input)
      warn "[DEPRECATED] Use 'docbook convert' instead of 'docbook to-html'"
      convert(input)
    end

    desc "to-single-page INPUT", "Alias for 'build'", hide: true
    option :output, aliases: "-o", required: true, desc: "Output HTML file"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes"
    option :image_search_dir, type: :array, desc: "Image search directories"
    option :image_strategy, default: "data_url", desc: "Image strategy"
    option :title, desc: "Page title"
    def to_single_page(input)
      warn "[DEPRECATED] Use 'docbook build' instead of 'docbook to-single-page'"
      build(input)
    end

    desc "to-docbook-mirror INPUT", "Alias for 'export'", hide: true
    option :output, aliases: "-o", desc: "Output file"
    option :pretty, type: :boolean, default: true, desc: "Pretty print"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes"
    def to_docbook_mirror(input)
      warn "[DEPRECATED] Use 'docbook export' instead of 'docbook to-docbook-mirror'"
      export(input)
    end

    def self.exit_on_failure?
      true
    end

    private

    FRONTEND_ROOT = File.expand_path("../../frontend/dist", __dir__)

    def read_input(input, resolve_xinclude = false)
      xml_string = File.read(input)
      if resolve_xinclude
        resolved = Docbook::XIncludeResolver.resolve_string(xml_string, base_path: input)
        resolved.to_xml
      else
        xml_string
      end
    end

    def parse_input(xml_string)
      Docbook::Document.from_xml(xml_string)
    end

    SCHEMAS_DIR = File.expand_path("schemas", __dir__)

    def validate_schema(doc, _input)
      schema_file = if input_xinclude?(doc)
                      File.join(SCHEMAS_DIR, "docbookxi.rng")
                    else
                      File.join(SCHEMAS_DIR, "docbook.rng")
                    end
      rng = File.read(schema_file)
      schema = Nokogiri::XML::RelaxNG(rng)
      schema.validate(doc)
    end

    def input_xinclude?(doc)
      doc.root.namespace_definitions.any? { |ns| ns.href == "http://www.w3.org/2001/XInclude" }
    end

    def write_output(content, output_path, output_type)
      if output_type == :directory
        raise ArgumentError, "Output path required for directory mode" unless output_path

        FileUtils.mkdir_p(output_path)
        File.write(File.join(output_path, "index.html"), content)

        assets_dir = File.join(output_path, "assets")
        FileUtils.mkdir_p(assets_dir)
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.css"), File.join(assets_dir, "app.css"))
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.iife.js"), File.join(assets_dir, "app.iife.js"))

        puts "Written to #{File.join(output_path, "index.html")} and assets/"
      elsif output_path
        File.write(output_path, content)
        puts "Written to #{output_path}"
      else
        $stdout.write(content)
      end
    end
  end
end
