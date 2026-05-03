# frozen_string_literal: true

module Docbook
  module Elements
    # Elements that have navigable child elements for TOC generation.
    # Override toc_children in each structural element to return its
    # ordered child elements.
    module TocContainer
      def toc_children
        []
      end
    end
  end
end
