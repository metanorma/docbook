# frozen_string_literal: true

module Docbook
  module Elements
    module HasNumber
      def self.included(base)
        base.class_eval { attribute :number, :string }
      end

      def numberable?
        true
      end
    end
  end
end
