# frozen_string_literal: true

module Docbook
  module Elements
    # Elements that have a displayable title.
    # Default: title.content → info.title.content → nil.
    # Override resolve_title in elements with different title paths.
    module Titled
      def resolve_title
        if title&.content
          title.content.join
        elsif info&.title&.content
          info.title.content.join
        end
      end

      def has_title?
        (t = resolve_title) && !t.strip.empty?
      end

      def titled?
        true
      end
    end
  end
end
