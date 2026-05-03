# frozen_string_literal: true

module Docbook
  module Elements
    # Elements that participate in document numbering.
    # Override numbering_role in each element to declare its role.
    module Numberable
      def numbering_role
        self.class::NUMBERING_ROLE
      end
    end
  end
end
