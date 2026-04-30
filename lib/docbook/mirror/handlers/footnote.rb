# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Footnote
        def self.call(element, context:)
          context.register_footnote(element)
        end

        def self.ref(element, context:)
          context.resolve_footnoteref(element)
        end
      end
    end
  end
end
