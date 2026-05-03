# frozen_string_literal: true

module Docbook
  module Elements
    # Base concern included by ALL elements.
    # Provides universal protocol methods so services use capability
    # queries instead of type introspection.
    # Provides universal protocol methods so services use capability
    # queries instead of type introspection.
    module DocbookElement
      def section_like?
        false
      end

      # Consistent element ID: xml_id or synthetic.
      def element_id
        id = xml_id
        id && !id.to_s.empty? ? id.to_s : "elem-#{object_id}"
      end

      def xml_id
        nil
      end

      def resolve_title
        nil
      end

      def has_title?
        false
      end

      def titled?
        false
      end

      def numbering_role
        nil
      end

      def toc_children
        []
      end

      def stats_category
        nil
      end

      def formal?
        false
      end

      def list_of_category
        nil
      end

      def index_term?
        false
      end

      # Protocol defaults for attribute access.
      # Overridden by Lutaml attribute declarations in the elements that have them.
      def title
        nil
      end

      def info
        nil
      end

      def indexterm
        []
      end

      def videoobject
        []
      end

      def imageobject
        []
      end

      def frame
        nil
      end

      def colsep
        nil
      end

      def rowsep
        nil
      end

      def fileref
        nil
      end

      def imagedata
        []
      end

      def number
        nil
      end

      def content
        nil
      end

      def text
        nil
      end

      def numberable?
        false
      end

      def media_children
        []
      end

      def xref?
        false
      end

      def callout_marker?
        false
      end

      def try_add_inline(_element)
        false
      end

      # Yield each child Lutaml::Model::Serializable from declared attributes.
      def walk_children
        self.class.attributes.each_value do |attr_def|
          value = send(attr_def.name)
          next if value.nil?

          case value
          when Array
            value.each { |v| yield v if v.is_a?(Lutaml::Model::Serializable) }
          when Lutaml::Model::Serializable
            yield value
          end
        end
      end
    end
  end
end
