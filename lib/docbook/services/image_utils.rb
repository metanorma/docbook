# frozen_string_literal: true

module Docbook
  module Services
    module ImageUtils
      def self.mime_type(path)
        case File.extname(path).downcase
        when ".png"  then "image/png"
        when ".jpg", ".jpeg" then "image/jpeg"
        when ".gif"  then "image/gif"
        when ".svg"  then "image/svg+xml"
        when ".webp" then "image/webp"
        end
      end

      def self.embed_as_data_url(path)
        return nil unless path && File.exist?(path)

        mime = mime_type(path)
        return path unless mime

        data = File.binread(path)
        "data:#{mime};base64,#{Base64.strict_encode64(data)}"
      rescue StandardError
        path
      end
    end
  end
end
