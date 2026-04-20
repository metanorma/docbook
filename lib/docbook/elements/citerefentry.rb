# frozen_string_literal: true

module Docbook
  module Elements
    class CiterefEntry < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :linkend, :string
      attribute :startvol, :string
      attribute :endvol, :string
      attribute :startpage, :string
      attribute :endpage, :string

      xml do
        element "citerefentry"
        mixed_content
        map_content to: :content
        map_attribute "linkend", to: :linkend
        map_attribute "startvol", to: :startvol
        map_attribute "endvol", to: :endvol
        map_attribute "startpage", to: :startpage
        map_attribute "endpage", to: :endpage
      end
    end
  end
end
