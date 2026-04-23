# frozen_string_literal: true

require "thor"
require "nokogiri"
require "fileutils"

module Docbook
  # Semantic errors raised by CLI commands. Thor rescues these and
  # displays them to the user via the error_stream.
  class CliError < StandardError; end
  class FileNotFoundError < CliError; end
  class ValidationError < CliError; end
  class LintError < CliError; end
  class ParseError < CliError; end

  class CLI < Thor
    class_option :verbose, type: :boolean, default: false,
                           desc: "Show detailed processing information"
    class_option :quiet, type: :boolean, default: false,
                         desc: "Suppress all output except errors"

    desc "version", "Show the docbook gem version"
    def version
      puts "docbook #{Docbook::VERSION}"
    end
    map %w[--version -v] => :version

    desc "build [INPUT]", "Build an interactive HTML reader from DocBook XML"
    option :output, aliases: "-o",
                    desc: "Output file or directory path (default: <input>.html or <input>/ with --format dist/paged)"
    option :demo, desc: "Build a bundled demo: xslTNG or model-flow"
    option :format, default: :inline, desc: "Output format: inline, dom, dist, paged"
    option :xinclude, type: :boolean, default: true,
                      desc: "Resolve XIncludes before processing"
    option :image_search_dir, type: :array,
                              desc: "Directories to search for images"
    option :image_strategy, default: "data_url",
                            desc: "Image resolution: data_url, file_url, or relative"
    option :sort_glossary, type: :boolean, default: false,
                           desc: "Sort glossary entries alphabetically"
    option :title, desc: "Page title (default: derived from document)"
    def build(input = nil)
      xml_path, output_path, search_dirs, title = if options[:demo]
                                                    demo_name = options[:demo]
                                                    demo_name = "xslTNG" if [true, "demo"].include?(demo_name)
                                                    build_demo_params(demo_name)
                                                  else
                                                    raise CliError, "Please provide an XML file. Usage: docbook build INPUT" unless input

                                                    build_file_params(input)
                                                  end

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      builder = Docbook::Output::Builder.new(
        xml_path: xml_path,
        output_path: output_path,
        format: options[:format].to_sym,
        image_search_dirs: search_dirs,
        image_strategy: options[:image_strategy].to_sym,
        sort_glossary: options[:sort_glossary],
        title: title,
      )
      result_path = builder.build

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      if verbose?
        stats = build_stats(result_path)
        verbose_step("  Completed in #{format_time(elapsed)}")
        verbose_step("  Output: #{result_path} (#{stats})")
      end

      say "Built #{result_path}"
    end

    desc "export INPUT", "Export DocBook XML as DocbookMirror JSON"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :pretty, type: :boolean, default: true, desc: "Pretty print JSON"
    option :sort_glossary, type: :boolean, default: false,
                           desc: "Sort glossary entries alphabetically"
    option :xinclude, type: :boolean, default: true,
                      desc: "Resolve XIncludes before processing"
    def export(input)
      require_relative "mirror"
      require_relative "output/docbook_mirror"
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      mirror_output = Docbook::Output::DocbookMirror.new(parsed, sort_glossary: options[:sort_glossary])
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

    desc "info INPUT", "Display document metadata and statistics"
    option :format, default: "text", desc: "Output format: text, json"
    def info(input)
      xml_string = read_input(input, true)
      parsed = parse_input(xml_string)

      stats = Docbook::Services::DocumentStats.new(parsed).generate

      case options[:format]
      when "json"
        require "json"
        puts JSON.pretty_generate(stats)
      else
        puts "Title: #{stats["title"]}" if stats["title"]
        puts "Author: #{stats["author"]}" if stats["author"]
        puts "Root: #{stats["root_element"]}"
        puts "Sections: #{stats["sections"]}"
        puts "Images: #{stats["images"]}"
        puts "Code blocks: #{stats["code_blocks"]}"
        puts "Tables: #{stats["tables"]}"
        puts "Index terms: #{stats["index_terms"]}"
        puts "Bibliography entries: #{stats["bibliography_entries"]}"
      end
    end

    desc "validate INPUT", "Validate DocBook XML"
    option :schema, type: :boolean, default: true,
                    desc: "Validate against DocBook 5 RELAX NG schema"
    option :wellformed, type: :boolean, default: false,
                        desc: "Check well-formedness only (no schema)"
    def validate(input)
      xml_string = File.read(input)
      doc = Nokogiri::XML(xml_string)

      # Well-formedness check
      if doc.errors.any?
        messages = doc.errors.map { |e| "#{input}: #{e}" }.join("\n")
        raise ValidationError, messages
      end
      verbose_step("  Well-formedness: OK")

      # Schema validation
      if options[:schema] && !options[:wellformed]
        errors = validate_schema(doc, input)
        if errors.any?
          messages = errors.map { |e| "#{input}: #{e}" }.join("\n")
          raise ValidationError, messages
        end
        verbose_step("  Schema (RELAX NG): OK")
      end

      # Additional checks in verbose mode
      if verbose?
        parsed = parse_input(xml_string)
        stats = Docbook::Services::DocumentStats.new(parsed).generate
        verbose_step("  Sections: #{stats["sections"]}")
        verbose_step("  Images: #{stats["images"]}")
        verbose_step("  Code blocks: #{stats["code_blocks"]}")
      end

      say "#{input}: valid"
    end

    desc "format INPUT", "Format/prettify DocBook XML"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :xinclude, type: :boolean, default: false,
                      desc: "Resolve XIncludes before processing"
    def format(input)
      xml_string = File.read(input)
      raw_doc = Nokogiri::XML(xml_string)

      if !options[:xinclude] && input_xinclude?(raw_doc)
        warn "Warning: Document contains XIncludes. Use --xinclude to resolve them."
      end

      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      output = parsed.to_xml(pretty: true, declaration: true, encoding: "utf-8")
      if options[:output]
        File.write(options[:output], output)
        say "Written to #{options[:output]}"
      else
        $stdout.write(output)
      end
    end

    desc "lint INPUT", "Check for common DocBook issues"
    option :strict, type: :boolean, default: false,
                    desc: "Also check cross-references and images"
    def lint(input)
      xml_path = File.expand_path(input)
      raise FileNotFoundError, "File not found: #{xml_path}. Check the path and try again." unless File.exist?(xml_path)

      xml_string = File.read(xml_path)
      raw_doc = Nokogiri::XML(xml_string)

      # Quick well-formedness check
      if raw_doc.errors.any?
        messages = raw_doc.errors.map { |e| "#{input}: #{e}" }.join("\n")
        raise ValidationError, messages
      end
      verbose_step("  Well-formedness: OK")

      parsed = begin
                 parse_input(xml_string)
      rescue StandardError => e
                 raise ParseError, "Parse error: #{e.message}. Check for duplicate xml:id values or invalid markup."
      end

      linter = Docbook::Services::Linter.new(parsed, input_path: xml_path)
      linter.check(strict: options[:strict])

      linter.errors.each do |err|
        warn "\e[31mError:\e[0m #{err[:message]} (#{err[:location]})"
      end
      linter.warnings.each do |warn_msg|
        warn "\e[33mWarning:\e[0m #{warn_msg[:message]} (#{warn_msg[:location]})"
      end

      if linter.ok?
        summary = if options[:strict]
                    "#{linter.errors.size} errors, #{linter.warnings.size} warnings"
                  else
                    "#{linter.errors.size} errors, #{linter.warnings.size} warnings (use --strict for xref/image checks)"
                  end
        say "#{input}: #{linter.warnings.any? ? "ok (with #{linter.warnings.size} warning#{"s" unless linter.warnings.size == 1})" : "ok"}"
        verbose_step("  #{summary}")
      else
        messages = linter.errors.map { |e| "#{e[:message]} (#{e[:location]})" }.join("\n")
        raise LintError, "#{linter.errors.size} issue#{"s" unless linter.errors.size == 1} found:\n#{messages}"
      end
    end

    desc "library INPUT", "Build a multi-book library from a directory or manifest"
    option :output, aliases: "-o",
                    desc: "Output file or directory path (default: library.html or library/ with --format dist/paged)"
    option :format, default: :inline, desc: "Output format: inline, dom, dist, paged"
    option :image_strategy, default: "data_url",
                            desc: "Image resolution: data_url, file_url, or relative"
    option :sort_glossary, type: :boolean, default: false,
                           desc: "Sort glossary entries alphabetically"
    option :title, desc: "Library title (default: derived from manifest or directory name)"
    def library(input)
      input_path = File.expand_path(input)
      unless File.exist?(input_path)
        raise FileNotFoundError, "Path not found: #{input_path}"
      end

      output_path = File.expand_path(options[:output] || derive_library_output(input))
      title = options[:title] || derive_library_title(input_path)

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      builder = Docbook::Output::LibraryBuilder.new(
        input_path: input_path,
        output_path: output_path,
        format: options[:format].to_sym,
        image_strategy: options[:image_strategy].to_sym,
        sort_glossary: options[:sort_glossary],
        title: title,
      )
      result_path = builder.build

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      if verbose?
        stats = build_stats(result_path)
        verbose_step("  Completed in #{format_time(elapsed)}")
        verbose_step("  Output: #{result_path} (#{stats})")
      end

      say "Built library: #{result_path}"
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
      raise ValidationError, "#{failures} roundtrip failure#{"s" unless failures == 1}" if failures.positive?
    end

    def self.exit_on_failure?
      true
    end

    private

    def read_input(input, resolve_xinclude = false)
      xml_string = File.read(input)
      if resolve_xinclude
        resolved = Docbook::XIncludeResolver.resolve_string(xml_string,
                                                            base_path: input)
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

    DEMO_FIXTURES = {
      "xslTNG" => {
        xml: "../../spec/fixtures/xslTNG/guide/xml/guide.xml",
        resources: "../../spec/fixtures/xslTNG/guide/resources",
        title: "DocBook XSLT 2.0 Stylesheet Reference",
      },
      "model-flow" => {
        xml: "../../spec/fixtures/art-of-the-model-flow/art-of-the-model-flow.xml",
        resources: "../../spec/fixtures/art-of-the-model-flow",
        title: "The Art of the Model Flow",
      },
    }.freeze

    def build_demo_params(demo_name)
      fixture = DEMO_FIXTURES[demo_name] || raise(CliError, "Unknown demo '#{demo_name}'. Available: #{DEMO_FIXTURES.keys.join(", ")}")
      fixture_xml = File.expand_path(fixture[:xml], __dir__)
      raise FileNotFoundError, "Demo fixture not found: #{fixture_xml}" unless File.exist?(fixture_xml)

      resources_dir = File.expand_path(fixture[:resources], __dir__)

      output_path = File.expand_path(options[:output] || "demo.html")
      title = options[:title] || fixture[:title]

      [fixture_xml, output_path, [resources_dir], title]
    end

    def build_file_params(input)
      xml_path = File.expand_path(input)
      raise FileNotFoundError, "File not found: #{xml_path}. Check the path and try again." unless File.exist?(xml_path)

      output_path = File.expand_path(options[:output] || derive_output_path(input))
      search_dirs = (options[:image_search_dir] || []).map do |d|
        File.expand_path(d)
      end
      title = options[:title] || File.basename(xml_path, ".xml")

      [xml_path, output_path, search_dirs, title]
    end

    def derive_output_path(input)
      base = File.basename(input, ".*")
      format = options[:format].to_sym
      ext = %i[dist paged].include?(format) ? "" : ".html"
      File.join(File.dirname(File.expand_path(input)), "#{base}#{ext}")
    end

    def derive_library_output(input)
      format = options[:format].to_sym
      ext = %i[dist paged].include?(format) ? "" : ".html"
      File.expand_path("library#{ext}")
    end

    def derive_library_title(input_path)
      if File.directory?(input_path)
        File.basename(input_path)
      else
        "DocBook Library"
      end
    end

    def verbose?
      options[:verbose] == true
    end

    def quiet?
      options[:quiet] == true
    end

    def say(msg)
      puts msg unless quiet?
    end

    def verbose_step(msg)
      puts msg if verbose?
    end

    def build_stats(output_path)
      size = File.size(output_path)
      format_bytes(size)
    end

    def format_bytes(bytes)
      if bytes < 1024
        "#{bytes}B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)}KB"
      else
        "#{(bytes / (1024.0 * 1024)).round(1)}MB"
      end
    end

    def format_time(seconds)
      if seconds < 1
        "#{(seconds * 1000).round(0)}ms"
      else
        "#{seconds.round(1)}s"
      end
    end

  end
end
