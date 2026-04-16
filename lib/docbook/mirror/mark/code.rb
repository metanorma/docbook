# frozen_string_literal: true

require_relative "base"

module Docbook
  module Mirror
    module Mark
      # Code mark with role attribute to distinguish DocBook code types:
      # - literal: <literal>
      # - code: <code>
      # - userinput: <userinput>
      # - computeroutput: <computeroutput>
      # - filename: <filename>
      # - classname: <classname>
      # - function: <function>
      # - parameter: <parameter>
      # - replaceable: <replaceable>
      class Code < Base
        PM_TYPE = "code"

        def initialize(role: "literal", **)
          super(**)
          @attrs[:role] = role
        end

        def role
          @attrs[:role]
        end

        def role=(value)
          @attrs[:role] = value
        end
      end
    end
  end
end
