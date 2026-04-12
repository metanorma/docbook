# frozen_string_literal: true


module Docbook
  module Elements
    class OrgName < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "orgname"
        mixed_content
        map_content to: :content
      end
    end
  end
end