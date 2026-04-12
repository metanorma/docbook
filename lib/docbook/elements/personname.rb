# frozen_string_literal: true


module Docbook
  module Elements
    class PersonName < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :firstname, FirstName
      attribute :surname, Surname
      attribute :honorific, Honorific

      xml do
        element "personname"
        mixed_content
        map_content to: :content
        map_element "firstname", to: :firstname
        map_element "surname", to: :surname
        map_element "honorific", to: :honorific
      end
    end
  end
end
