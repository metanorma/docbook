# frozen_string_literal: true

require "thor"
require "nokogiri"
require "fileutils"

module Docbook
  class CLI < Thor
    desc "build [INPUT]", "Build an interactive HTML reader from DocBook XML"
    option :output, aliases: "-o", desc: "Output HTML file path (default: <input>.html or demo.html with --demo)"
    option :demo, type: :boolean, desc: "Build using the bundled DocBook sample"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    option :image_search_dir, type: :array, desc: "Directories to search for images"
    option :image_strategy, default: "data_url", desc: "Image resolution: data_url, file_url, or relative"
    option :title, desc: "Page title (default: derived from document)"
    def build(input = nil)
      xml_path, output_path, search_dirs, title = if options[:demo]
                                                    build_demo_params
                                                  else
                                                    abort "INPUT is required (or use --demo for the bundled sample)" unless input

                                                    build_file_params(input)
                                                  end

      page = Docbook::Output::SinglePage.new(
        xml_path: xml_path,
        output_path: output_path,
        image_search_dirs: search_dirs,
        image_strategy: options[:image_strategy].to_sym,
        title: title
      )

      page.generate
      puts "Built #{output_path}"
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
      if options[:output]
        File.write(options[:output], output)
        puts "Written to #{options[:output]}"
      else
        $stdout.write(output)
      end
    end

    # ---- Development commands (hidden from help) ----

    desc "roundtrip INPUT...", "Round-trip test DocBook XML files", hide: true
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

    def self.exit_on_failure?
      true
    end

    private

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

    def build_demo_params
      fixture_xml = File.expand_path("../../spec/fixtures/xslTNG/guide/xml/guide.xml", __dir__)
      abort "Demo fixture not found: #{fixture_xml}" unless File.exist?(fixture_xml)

      xml_dir = File.dirname(fixture_xml)
      resources_dir = File.join(xml_dir, "..", "resources")

      output_path = File.expand_path(options[:output] || "demo.html")
      title = options[:title] || "DocBook XSLT 2.0 Stylesheet Reference"

      [fixture_xml, output_path, [resources_dir], title]
    end

    def build_file_params(input)
      xml_path = File.expand_path(input)
      output_path = File.expand_path(options[:output] || derive_output_path(input))
      search_dirs = (options[:image_search_dir] || []).map { |d| File.expand_path(d) }
      title = options[:title] || File.basename(xml_path, ".xml")

      [xml_path, output_path, search_dirs, title]
    end

    def derive_output_path(input)
      base = File.basename(input, ".*")
      File.join(File.dirname(File.expand_path(input)), "#{base}.html")
    end
  end
end
