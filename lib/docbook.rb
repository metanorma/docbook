# frozen_string_literal: true

require "lutaml/model"

module Docbook
  class Error < StandardError; end

  autoload :Version, "#{__dir__}/docbook/version"
  autoload :Elements, "#{__dir__}/docbook/elements"
  autoload :Models, "#{__dir__}/docbook/models"
  autoload :Services, "#{__dir__}/docbook/services"
  autoload :XIncludeResolver, "#{__dir__}/docbook/xinclude_resolver"
  autoload :XrefResolver, "#{__dir__}/docbook/xref_resolver"
  autoload :Output, "#{__dir__}/docbook/output"
  autoload :CLI, "#{__dir__}/docbook/cli"
  autoload :Document, "#{__dir__}/docbook/document"
end
