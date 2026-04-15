# frozen_string_literal: true

module Docbook
  module Services
    # Shared helpers for consistent element ID generation and title resolution.
    # Used by TocGenerator, NumberingService, and Mirror::Transformer
    # to ensure IDs match between TOC, numbering, and rendered DOM.
    module ElementIdHelper
      # Consistent ID for any element.
      # For RefEntry: xml_id → p_{varname} → elem-{object_id}
      # For others: xml_id → elem-{object_id}
      def element_id(element)
        if element.is_a?(Docbook::Elements::RefEntry)
          refentry_id(element)
        else
          id = element.xml_id if element.respond_to?(:xml_id)
          id && !id.to_s.empty? ? id.to_s : "elem-#{element.object_id}"
        end
      end

      # Consistent ID for RefEntry elements.
      # Priority: xml_id → p_{varname} (from fieldsynopsis) → synthetic
      def refentry_id(ref)
        id = ref.xml_id if ref.respond_to?(:xml_id)
        return id.to_s if id && !id.to_s.empty?

        if ref.respond_to?(:refmeta) && ref.refmeta
          fs = ref.refmeta.fieldsynopsis if ref.refmeta.respond_to?(:fieldsynopsis)
          if fs && !fs.empty?
            varname = fs.first.varname
            return "p_#{varname.content}" if varname && !varname.content.to_s.empty?
          end
        end

        "elem-#{ref.object_id}"
      end

      # Resolve the display title for a RefEntry.
      # Priority: refentrytitle → fieldsynopsis.varname → refname → nil
      def resolve_refentry_title(ref)
        if ref.respond_to?(:refmeta) && ref.refmeta
          meta = ref.refmeta
          if meta.respond_to?(:refentrytitle) && meta.refentrytitle
            title = meta.refentrytitle
            return title.content.to_s if title.respond_to?(:content) && title.content
          end
          if meta.respond_to?(:fieldsynopsis) && meta.fieldsynopsis && !meta.fieldsynopsis.empty?
            vn = meta.fieldsynopsis.first.varname
            return vn.content.to_s if vn && vn.respond_to?(:content) && vn.content
          end
        end

        if ref.respond_to?(:refnamediv) && ref.refnamediv && ref.refnamediv.respond_to?(:refname)
          names = ref.refnamediv.refname
          return names.map(&:content).join(", ") if names && !names.empty?
        end

        nil
      end
    end
  end
end
