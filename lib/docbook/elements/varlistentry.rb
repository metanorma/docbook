# frozen_string_literal: true

module Docbook
  module Elements
    class Varlistentry < Lutaml::Model::Serializable
      attribute :term, Term, collection: true
      attribute :listitem, ListItem

      xml do
        element "varlistentry"
        map_element "term", to: :term
        map_element "listitem", to: :listitem
      end
    end
  end
end
