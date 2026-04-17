# frozen_string_literal: true

module Docbook
  module Services
    # Lightweight lint checks for DocBook documents.
    #
    # Checks for common issues without requiring full RELAX NG validation:
    # duplicate IDs, broken cross-references, missing images, empty sections.
    #
    # Usage:
    #   linter = Docbook::Services::Linter.new(parsed_doc)
    #   result = linter.check(strict: true)
    #   result.errors   # => [{ message: "...", location: "..." }]
    #   result.warnings # => [{ message: "...", location: "..." }]
    #
    class Linter
      attr_reader :errors, :warnings

      def initialize(document, input_path: nil)
        @document = document
        @input_path = input_path
        @errors = []
        @warnings = []
      end

      def check(strict: false)
        check_duplicate_ids
        check_empty_elements
        if strict
          check_broken_xrefs
          check_missing_images
        end
        self
      end

      def ok?
        @errors.empty?
      end

      private

      def check_duplicate_ids
        ids = {}
        walk_ids(@document, ids)
        ids.each do |id, locations|
          next unless locations.size > 1

          @errors << {
            message: "Duplicate xml:id '#{id}' (found #{locations.size} times)",
            location: locations.join(", "),
          }
        end
      end

      def walk_ids(el, ids)
        return unless el.is_a?(Lutaml::Model::Serializable)

        if el.respond_to?(:xml_id) && el.xml_id
          id = el.xml_id.to_s
          loc = element_location(el)
          ids[id] ||= []
          ids[id] << loc
        end

        walk_children(el) { |child| walk_ids(child, ids) }
      end

      def check_empty_elements
        check_empty_titled(@document)
      end

      def check_empty_titled(el)
        return unless el.is_a?(Lutaml::Model::Serializable)

        if el.respond_to?(:title) && el.title
          has_content = has_block_content?(el)
          unless has_content
            name = el.class.name.split("::").last
            title_text = text_of(el.title)
            @warnings << {
              message: "Empty #{name}: #{title_text || "(untitled)"}",
              location: element_location(el),
            }
          end
        end

        walk_children(el) { |child| check_empty_titled(child) }
      end

      def has_block_content?(el)
        return false unless el.class.respond_to?(:attributes)

        el.class.attributes.each_value do |attr_def|
          next if ["title", "info", "xml_id"].include?(attr_def.name)

          value = el.send(attr_def.name)
          case value
          when Array
            return true if value.any? { |v| walkable?(v) || (v.is_a?(String) && v.strip != "") }
          when Lutaml::Model::Serializable
            return true
          when String
            return true if value.strip != ""
          end
        end
        false
      end

      def check_broken_xrefs
        id_map = build_id_map(@document)
        collect_xrefs(@document, id_map)
      end

      def build_id_map(el, map = Set.new)
        return map unless el.is_a?(Lutaml::Model::Serializable)

        map << el.xml_id.to_s if el.respond_to?(:xml_id) && el.xml_id
        walk_children(el) { |child| build_id_map(child, map) }
        map
      end

      def collect_xrefs(el, id_map)
        return unless el.is_a?(Lutaml::Model::Serializable)

        if el.is_a?(Elements::Xref) && el.respond_to?(:linkend) && el.linkend && !id_map.include?(el.linkend.to_s)
          @errors << {
            message: "Broken xref: '#{el.linkend}' does not match any xml:id",
            location: element_location(el),
          }
        end

        walk_children(el) { |child| collect_xrefs(child, id_map) }
      end

      def check_missing_images
        return unless @input_path

        xml_dir = File.dirname(@input_path)
        collect_image_refs(@document, xml_dir)
      end

      def collect_image_refs(el, xml_dir)
        return unless el.is_a?(Lutaml::Model::Serializable)

        # Check mediaobject/videodata/imagedata filerefs
        if el.respond_to?(:videoobject) && el.videoobject
          check_media_data(el.videoobject, xml_dir)
        end
        if el.respond_to?(:imageobject) && el.imageobject
          check_media_data(el.imageobject, xml_dir)
        end

        walk_children(el) { |child| collect_image_refs(child, xml_dir) }
      end

      def check_media_data(media_obj, xml_dir)
        return unless media_obj

        children = if media_obj.respond_to?(:content)
                     Array(media_obj.content)
                   elsif media_obj.respond_to?(:imagedata)
                     Array(media_obj.imagedata)
                   else
                     []
                   end

        children.each do |child|
          next unless child.respond_to?(:fileref)
          next if child.fileref.nil?

          src = child.fileref.to_s
          next if src.start_with?("http://", "https://", "data:")

          abs_path = File.expand_path(src, xml_dir)
          unless File.exist?(abs_path)
            @warnings << {
              message: "Image not found: #{src}",
              location: abs_path,
            }
          end
        end
      end

      def walk_children(el)
        return unless el.class.respond_to?(:attributes)

        el.class.attributes.each_value do |attr_def|
          value = el.send(attr_def.name)
          next if value.nil?

          case value
          when Array
            value.each { |v| yield v if walkable?(v) }
          else
            yield value if walkable?(value)
          end
        end
      end

      def walkable?(value)
        value.is_a?(Lutaml::Model::Serializable)
      end

      def element_location(el)
        if el.respond_to?(:xml_id) && el.xml_id
          "xml:id='#{el.xml_id}'"
        else
          "<#{el.class.name.split("::").last}>"
        end
      end

      def text_of(title)
        return nil unless title

        content = title.content
        return nil unless content

        text = content.is_a?(Array) ? content.join : content.to_s
        text.strip.empty? ? nil : text.strip
      end
    end
  end
end
