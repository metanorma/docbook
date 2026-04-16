# frozen_string_literal: true

module Docbook
  module Mirror
    class Error < StandardError; end

    autoload :Version, "#{__dir__}/mirror/version"
    autoload :Node, "#{__dir__}/mirror/node"
    autoload :Mark, "#{__dir__}/mirror/mark"
    autoload :Transformer, "#{__dir__}/mirror/transformer"
  end
end
