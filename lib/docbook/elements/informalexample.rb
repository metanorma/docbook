# frozen_string_literal: true


module Docbook
  module Elements
    class InformalExample < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :para, Para, collection: true
      attribute :programlisting, ProgramListing, collection: true
      attribute :screen, Screen, collection: true
      attribute :literallayout, LiteralLayout, collection: true

      xml do
        element "informalexample"
        mixed_content
        map_content to: :content
        map_element "para", to: :para
        map_element "programlisting", to: :programlisting
        map_element "screen", to: :screen
        map_element "literallayout", to: :literallayout
      end
    end
  end
end