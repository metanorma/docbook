# frozen_string_literal: true

module Docbook
  module Elements
    class RefNamediv < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :refname, RefName, collection: true
      attribute :refpurpose, RefPurpose
      attribute :refclass, RefPurpose

      xml do
        element "refnamediv"
        mixed_content
        map_content to: :content
        map_element "refname", to: :refname
        map_element "refpurpose", to: :refpurpose
        map_element "refclass", to: :refclass
      end
    end
  end
end
