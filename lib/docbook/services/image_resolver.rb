# frozen_string_literal: true

module Docbook
  module Services
    # Resolves relative image paths to absolute URLs.
    #
    # Walks a DocbookMirror JSON structure and converts image src values
    # from relative paths to absolute URLs using the configured strategy.
    #
    # Usage:
    #   resolver = ImageResolver.new(
    #     search_dirs: ["/path/to/xml", "/path/to/resources"],
    #     strategy: :file_url  # or :data_url, :relative
    #   )
    #   resolver.resolve(data)
    #
    class ImageResolver
      STRATEGIES = %i[file_url data_url relative].freeze

      attr_reader :search_dirs, :strategy

      # @param search_dirs [Array<String>] directories to search for images
      # @param strategy [Symbol] resolution strategy:
      #   - :file_url  — convert to file:// URLs (for local file:// viewing)
      #   - :data_url  — embed as data: URLs (self-contained HTML)
      #   - :relative  — keep as relative paths (for HTTP serving)
      # @param base_url [String] base URL for :relative strategy
      def initialize(search_dirs:, strategy: :file_url, base_url: nil)
        @search_dirs = Array(search_dirs)
        @strategy = strategy
        @base_url = base_url
      end

      # Resolve image paths in a DocbookMirror JSON structure (mutates in place).
      # @param data [Hash] the JSON data structure
      def resolve(data)
        walk(data)
      end

      private

      def walk(obj)
        case obj
        when Hash
          resolve_image(obj) if obj["type"] == "image" && obj.dig("attrs",
                                                                  "src")
          obj.each_value { |v| walk(v) }
        when Array
          obj.each { |v| walk(v) }
        end
      end

      def resolve_image(node)
        src = node.dig("attrs", "src")
        return if src.nil? || src.start_with?("http", "data:")

        # Already resolved?
        return if src.start_with?("file://")

        abs_path = find_image(src)
        if abs_path
          case @strategy
          when :file_url
            node["attrs"]["src"] = "file://#{abs_path}"
          when :data_url
            node["attrs"]["src"] = embed_data_url(abs_path)
          when :relative
            # Keep relative if base_url is set, adjust path
            # For now just keep as-is
          end
        else
          warn "docbook: image not found: #{src} (searched in #{search_dirs.join(", ")})"
        end
      end

      def find_image(src)
        @search_dirs.each do |dir|
          abs_path = File.expand_path(src, dir)
          return abs_path if File.exist?(abs_path)
        end
        nil
      end

      def embed_data_url(path)
        mime = mime_type(path)
        return path unless mime

        data = File.binread(path)
        encoded = Base64.strict_encode64(data)
        "data:#{mime};base64,#{encoded}"
      rescue StandardError
        path
      end

      def mime_type(path)
        case File.extname(path).downcase
        when ".png"  then "image/png"
        when ".jpg", ".jpeg" then "image/jpeg"
        when ".gif"  then "image/gif"
        when ".svg"  then "image/svg+xml"
        when ".webp" then "image/webp"
        end
      end
    end
  end
end
