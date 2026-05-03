# frozen_string_literal: true

module Docbook
  module Elements
    # Marker concern for structural/section elements that appear in TOC.
    # Overrides DocbookElement#section_like? to return true.
    module SectionLike
      def section_like?
        true
      end
    end
  end
end
