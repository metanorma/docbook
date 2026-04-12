# frozen_string_literal: true


module Docbook
  module Elements
    class Xref < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :linkend, :string

      xml do
        element "xref"
        mixed_content
        map_content to: :content
        map_attribute "linkend", to: :linkend
      end
    end
  end
end
