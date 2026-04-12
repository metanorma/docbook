# frozen_string_literal: true


module Docbook
  module Elements
    class Code < Lutaml::Model::Serializable
      attribute :content, :string

      xml do
        element "code"
        mixed_content
        map_content to: :content
      end
    end
  end
end
