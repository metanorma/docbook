# frozen_string_literal: true

module Docbook
  module Output
    autoload :Html, "#{__dir__}/output/html"
    autoload :Data, "#{__dir__}/output/data"
  end
end
