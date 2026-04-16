# frozen_string_literal: true

module Docbook
  module Elements
    class Bibliomixed < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :xml_id, Lutaml::Xml::W3c::XmlIdType
      attribute :role, :string
      attribute :abbrev, Abbrev
      attribute :citetitle, Citetitle, collection: true
      attribute :link, Link, collection: true
      attribute :pubdate, :string
      attribute :orgname, OrgName, collection: true
      attribute :publishername, PublisherName, collection: true
      attribute :author, Author, collection: true
      attribute :personname, PersonName, collection: true
      attribute :firstname, FirstName
      attribute :surname, Surname

      xml do
        element "bibliomixed"
        mixed_content
        map_content to: :content
        map_attribute "xml:id", to: :xml_id
        map_attribute "role", to: :role
        map_element "abbrev", to: :abbrev
        map_element "citetitle", to: :citetitle
        map_element "link", to: :link
        map_element "pubdate", to: :pubdate
        map_element "orgname", to: :orgname
        map_element "publishername", to: :publishername
        map_element "author", to: :author
        map_element "personname", to: :personname
        map_element "firstname", to: :firstname
        map_element "surname", to: :surname
      end
    end
  end
end
