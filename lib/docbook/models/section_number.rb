# frozen_string_literal: true

module Docbook
  module Models
    # Section Number - pre-computed numbering for sections
    class SectionNumber < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :number, :string  # "I", "1", "1.2", "A", etc.
      attribute :type, :string  # part, chapter, section, appendix, refentry

      json do
        map "id", to: :id
        map "number", to: :number
        map "type", to: :type
      end
    end
  end
end
