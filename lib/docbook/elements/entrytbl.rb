# frozen_string_literal: true


module Docbook
  module Elements
    class EntryTbl < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :cols, :string
      attribute :colname, :string
      attribute :spanname, :string

      xml do
        element "entrytbl"
        mixed_content
        map_content to: :content
        map_attribute "cols", to: :cols
        map_attribute "colname", to: :colname
        map_attribute "spanname", to: :spanname
      end
    end
  end
end
