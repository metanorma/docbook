# frozen_string_literal: true

module Docbook
  module Output
    class LibraryBuilder
      attr_reader :input_path, :output_path, :format, :options

      def initialize(input_path:, output_path:, format: :inline, **options)
        @input_path = input_path
        @output_path = output_path
        @format = format
        @options = options
      end

      def build
        manifest_resolver = Services::CollectionManifestResolver.new(@input_path)
        manifest = manifest_resolver.resolve

        if manifest.books.empty?
          raise ArgumentError, "No DocBook XML files found in #{@input_path}"
        end

        guides = manifest.books.map do |book|
          Pipeline.new(
            xml_path: book.source,
            image_strategy: @options[:image_strategy] || :data_url,
            sort_glossary: @options[:sort_glossary] || false,
            title: book.title || File.basename(book.source, ".*"),
          ).process
        end

        format_class = Formats::FORMAT_MAP[@format]
        raise ArgumentError, "Unknown format: #{@format}" unless format_class

        formatter = format_class.new(dist_dir: @options[:dist_dir])
        formatter.write_library(@output_path, guides, manifest: manifest, title: @options[:title])

        @output_path
      end
    end
  end
end
