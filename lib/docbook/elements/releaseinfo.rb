# frozen_string_literal: true

module Docbook
  module Elements
    class ReleaseInfo < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "releaseinfo"
        mixed_content
        map_content to: :content
      end
    end
  end
end
