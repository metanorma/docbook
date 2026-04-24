# frozen_string_literal: true

require "yaml"

module Docbook
  module Services
    # Resolves a collection manifest from a directory, JSON file, or YAML file.
    #
    # Directory mode: auto-discovers *.xml files in subdirectories and finds
    # cover images (cover.png/jpg/jpeg/gif/svg/webp) by convention.
    #
    # Manifest mode: parses JSON or YAML files into a CollectionManifest model,
    # then resolves relative paths to absolute paths.
    #
    # Returns a CollectionResult with :name, :description, and :books (array of
    # ResolvedBook structs with absolute paths).
    #
    # Usage:
    #   result = CollectionManifestResolver.resolve("/path/to/collection")
    #   result.books.each { |book| puts book.source }
    #
    class CollectionManifestResolver
      COVER_EXTENSIONS = %w[png jpg jpeg gif svg webp].freeze
      COVER_BASENAME = "cover"

      ResolvedBook = Struct.new(:id, :source, :title, :author, :description,
                                :cover, keyword_init: true)
      CollectionResult = Struct.new(:name, :description, :books, keyword_init: true)

      # @param path [String] path to a directory, JSON file, or YAML file
      # @return [CollectionResult] resolved collection with :name, :description, :books
      def self.resolve(path)
        new(path).resolve
      end

      def initialize(path)
        @path = File.expand_path(path)
      end

      def resolve
        if File.directory?(@path)
          resolve_directory
        elsif json_file?
          resolve_json_file
        elsif yaml_file?
          resolve_yaml_file
        else
          raise ArgumentError, "Unsupported path: #{@path} (must be a directory, .json, .yml, or .yaml file)"
        end
      end

      private

      def resolve_directory
        books = discover_books(@path)

        CollectionResult.new(name: File.basename(@path), description: nil, books: books)
      end

      def resolve_json_file
        content = File.read(@path)
        manifest = Models::CollectionManifest.from_json(content)
        build_result(manifest)
      end

      def resolve_yaml_file
        content = File.read(@path)
        data = YAML.safe_load(content)
        json_str = JSON.generate(data)
        manifest = Models::CollectionManifest.from_json(json_str)
        build_result(manifest)
      end

      def build_result(manifest)
        base_dir = File.dirname(@path)
        books = manifest.books.map do |book|
          resolve_book(book, base_dir)
        end

        CollectionResult.new(name: manifest.name, description: manifest.description, books: books)
      end

      def resolve_book(book, base_dir)
        source = book.source ? File.expand_path(book.source, base_dir) : nil
        cover = book.cover ? File.expand_path(book.cover, base_dir) : nil

        ResolvedBook.new(
          id: book.id,
          source: source,
          title: book.title,
          author: book.author,
          description: book.description,
          cover: cover,
        )
      end

      def discover_books(dir)
        xml_files = Dir.glob(File.join(dir, "*", "*.xml"))

        xml_files.map do |xml_path|
          subdir = File.dirname(xml_path)
          id = File.basename(subdir)

          ResolvedBook.new(
            id: id,
            source: xml_path,
            title: nil,
            author: nil,
            description: nil,
            cover: find_cover(subdir),
          )
        end
      end

      def find_cover(subdir)
        COVER_EXTENSIONS.each do |ext|
          path = File.join(subdir, "#{COVER_BASENAME}.#{ext}")
          return path if File.exist?(path)
        end
        nil
      end

      def json_file?
        File.exist?(@path) && @path.end_with?(".json")
      end

      def yaml_file?
        File.exist?(@path) && @path.end_with?(".yml", ".yaml")
      end
    end
  end
end
