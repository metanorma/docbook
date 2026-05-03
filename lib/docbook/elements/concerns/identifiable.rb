# frozen_string_literal: true

module Docbook
  module Elements
    # Elements with xml_id — overrides element_id to access xml_id directly.
    # DocbookElement provides element_id using protocol methods.
    # This concern optimizes for elements that always have xml_id declared.
    module Identifiable
      def element_id
        id = xml_id
        id && !id.to_s.empty? ? id.to_s : "elem-#{object_id}"
      end
    end
  end
end
