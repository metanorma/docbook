# frozen_string_literal: true


module Docbook
  module Elements
    class SubSteps < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :step, Step, collection: true

      xml do
        element "substeps"
        mixed_content
        map_content to: :content
        map_element "step", to: :step
      end
    end
  end
end
