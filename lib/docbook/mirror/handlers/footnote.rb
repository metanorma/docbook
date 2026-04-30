# frozen_string_literal: true

module Docbook
  module Mirror
    module Handlers
      class Footnote
        def self.call(el, context:)
          context.register_footnote(el)
        end

        def self.ref(el, context:)
          context.resolve_footnoteref(el)
        end
      end
    end
  end
end
