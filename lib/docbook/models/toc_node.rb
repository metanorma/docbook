# frozen_string_literal: true

module Docbook
  module Models
    # TOC Node - represents a single entry in the table of contents
    class TocNode < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :title, :string
      attribute :type, :string  # part, chapter, section, appendix, reference
      attribute :number, :string
      attribute :children, TocNode, collection: true
      attribute :page, :integer  # Page number for PDF navigation

      json do
        map "id", to: :id
        map "title", to: :title
        map "type", to: :type
        map "number", to: :number
        map "children", to: :children
        map "page", to: :page
      end
    end
  end
end
