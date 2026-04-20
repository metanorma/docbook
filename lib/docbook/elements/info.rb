# frozen_string_literal: true

module Docbook
  module Elements
    class Info < Lutaml::Model::Serializable
      attribute :content, :string, collection: true
      attribute :title, Title
      attribute :subtitle, Subtitle
      attribute :doc_date, Docbook::Elements::Date
      attribute :pubdate, PubDate
      attribute :author, Author, collection: true
      attribute :orgname, OrgName, collection: true
      attribute :productname, ProductName, collection: true
      attribute :copyright, Copyright, collection: true
      attribute :legalnotice, LegalNotice, collection: true
      attribute :mediaobject, MediaObject, collection: true
      attribute :releaseinfo, ReleaseInfo
      attribute :abstract, Para, collection: true

      xml do
        element "info"
        mixed_content

        map_content to: :content
        map_element "title", to: :title
        map_element "subtitle", to: :subtitle
        map_element "date", to: :doc_date
        map_element "pubdate", to: :pubdate
        map_element "author", to: :author
        map_element "orgname", to: :orgname
        map_element "productname", to: :productname
        map_element "copyright", to: :copyright
        map_element "legalnotice", to: :legalnotice
        map_element "mediaobject", to: :mediaobject
        map_element "releaseinfo", to: :releaseinfo
        map_element "abstract", to: :abstract
      end
    end
  end
end
