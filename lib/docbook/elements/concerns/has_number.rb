# frozen_string_literal: true

module Docbook
  module Elements
    # Adds common structural attributes to sectioning elements.
    module HasNumber
      def self.included(base)
        base.class_eval { attribute :number, :string }
      end
    end
  end
end
