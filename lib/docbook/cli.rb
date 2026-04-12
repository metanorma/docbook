# frozen_string_literal: true

require "thor"
require "nokogiri"
require "fileutils"

module Docbook
  class CLI < Thor
    desc "format INPUT", "Format/prettify DocBook XML"
    option :output, aliases: "-o", desc: "Output file (default: stdout)"
    option :xinclude, type: :boolean, default: false, desc: "Resolve XIncludes before processing"
    def format(input)
      xml_string = read_input(input, options[:xinclude])
      parsed = parse_input(xml_string)
      output = parsed.to_xml(pretty: true, declaration: true, encoding: "utf-8")
      write_output(output, options[:output], :single_file)
    end

    desc "validate INPUT", "Validate DocBook XML well-formedness"
    def validate(input)
      xml_string = File.read(input)
      doc = Nokogiri::XML(xml_string)
      if doc.errors.empty?
        puts "#{input}: valid"
      else
        doc.errors.each { |e| warn "#{input}: #{e}" }
        exit 1
      end
    end

    desc "to-html INPUT", "Convert DocBook XML to HTML"
    option :output, aliases: "-o", desc: "Output file or directory"
    option :xinclude, type: :boolean, default: true, desc: "Resolve XIncludes before processing"
    option :output_type, default: :single_file, desc: "Output type: single_file or directory"
    def to_html(input)
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

    desc "roundtrip INPUT...", "Round-trip test DocBook XML files"
    def roundtrip(*inputs)
      failures = 0
      inputs.each do |input|
        xml_string = File.read(input)
        begin
          parsed = parse_input(xml_string)
          output = parsed.to_xml(declaration: true, encoding: "utf-8")
          reparsed = parse_input(output)
          puts "#{input}: OK"
        rescue StandardError => e
          warn "#{input}: FAIL - #{e.message}"
          failures += 1
        end
      end
      warn "#{inputs.size} files, #{failures} failures"
      exit 1 if failures > 0
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

    def write_output(content, output_path, output_type)
      if output_type == :directory
        raise ArgumentError, "Output path required for directory mode" unless output_path

        FileUtils.mkdir_p(output_path)
        File.write(File.join(output_path, "index.html"), content)

        # Copy frontend assets to output_dir/assets/
        assets_dir = File.join(output_path, "assets")
        FileUtils.mkdir_p(assets_dir)
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.css"), File.join(assets_dir, "app.css"))
        FileUtils.cp(File.join(FRONTEND_ROOT, "app.iife.js"), File.join(assets_dir, "app.iife.js"))

        puts "Written to #{File.join(output_path, "index.html")} and assets/"
      else
        if output_path
          File.write(output_path, content)
          puts "Written to #{output_path}"
        else
          $stdout.write(content)
        end
      end
    end
  end
end
