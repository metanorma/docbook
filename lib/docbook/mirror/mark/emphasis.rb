# frozen_string_literal: true

require_relative "base"

module Docbook
  module Mirror
    module Mark
      class Emphasis < Base
        PM_TYPE = 'emphasis'
      end

      class Strong < Base
        PM_TYPE = 'strong'
      end

      class Italic < Base
        PM_TYPE = 'italic'
      end
    end
  end
end
