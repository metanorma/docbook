# frozen_string_literal: true

module Docbook
  module Output
    autoload :Pipeline, "#{__dir__}/output/pipeline"
    autoload :HtmlRenderer, "#{__dir__}/output/html_renderer"
    autoload :Builder, "#{__dir__}/output/builder"
    autoload :LibraryBuilder, "#{__dir__}/output/library_builder"

    module Formats
      autoload :BaseFormat, "#{__dir__}/output/formats/base_format"
      autoload :InlineFormat, "#{__dir__}/output/formats/inline_format"
      autoload :DomFormat, "#{__dir__}/output/formats/dom_format"
      autoload :DistFormat, "#{__dir__}/output/formats/dist_format"
      autoload :PagedFormat, "#{__dir__}/output/formats/paged_format"

      FORMAT_MAP = {
        inline: InlineFormat,
        dom: DomFormat,
        dist: DistFormat,
        paged: PagedFormat,
      }.freeze
    end
  end
end
