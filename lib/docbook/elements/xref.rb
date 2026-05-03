# frozen_string_literal: true

module Docbook
  module Elements
    class Xref < Lutaml::Model::Serializable
      include DocbookElement

      attribute :content, :string, collection: true
      attribute :linkend, :string

      def xref?
        true
      end

      xml do
        element "xref"
        mixed_content
        map_content to: :content
        map_attribute "linkend", to: :linkend
      end
    end
  end
end
