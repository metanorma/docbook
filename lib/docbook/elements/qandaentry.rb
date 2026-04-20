# frozen_string_literal: true

module Docbook
  module Elements
    class QandAEntry < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :question, Question
      attribute :answer, Answer, collection: true

      xml do
        element "qandaentry"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_element "question", to: :question
        map_element "answer", to: :answer
      end
    end
  end
end
