# frozen_string_literal: true

module Docbook
  module Elements
    class Step < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :title, Title
      attribute :para, Para, collection: true
      attribute :substeps, SubSteps, collection: true
      attribute :programlisting, ProgramListing, collection: true

      xml do
        element "step"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "title", to: :title
        map_element "para", to: :para
        map_element "substeps", to: :substeps
        map_element "programlisting", to: :programlisting
      end
    end
  end
end
