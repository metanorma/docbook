# frozen_string_literal: true

module Docbook
  module Mirror
    class Mark
      PM_TYPE = 'mark'

      attr_accessor :type, :attrs

      def initialize(type: nil, attrs: {})
        @type = type || self.class::PM_TYPE
        @attrs = attrs || {}
      end

      def to_h
        result = { 'type' => type }
        result['attrs'] = attrs.transform_keys(&:to_s) if attrs && !attrs.empty?
        result
      end

      alias to_hash to_h

      def to_json(**options)
        to_h.to_json(options)
      end

      def self.from_h(hash)
        return nil unless hash

        type = hash['type']
        attrs = hash['attrs'] || {}

        mark_class = MARKS[type] || Mark

        # Use class-specific from_h if this class defines its own class method (not inherited)
        if mark_class != Mark && mark_class.singleton_class.instance_methods(false).include?(:from_h)
          mark_class.from_h(hash)
        else
          mark_class.new(
            attrs: attrs.transform_keys(&:to_sym)
          )
        end
      end

      MARKS = {}

      # Base class for marks
      class Base < Mark
      end

      class Emphasis < Base
        PM_TYPE = 'emphasis'
      end

      class Strong < Base
        PM_TYPE = 'strong'
      end

      class Italic < Base
        PM_TYPE = 'italic'
      end

      # Code mark with role attribute to distinguish DocBook code types
      class Code < Base
        PM_TYPE = 'code'

        def initialize(role: 'literal', **kwargs)
          super(**kwargs)
          @attrs[:role] = role
        end

        def role
          @attrs[:role]
        end

        def self.from_h(hash)
          return nil unless hash
          attrs = hash['attrs'] || {}
          role = attrs[:role] || attrs['role'] || 'literal'
          new(role: role)
        end
      end

      class Link < Base
        PM_TYPE = 'link'

        def initialize(href: nil, linkend: nil, **kwargs)
          super(**kwargs)
          @attrs[:href] = href if href
          @attrs[:linkend] = linkend if linkend
        end
      end

      class Xref < Base
        PM_TYPE = 'xref'

        def initialize(linkend:, resolved: nil, **kwargs)
          super(**kwargs)
          @attrs[:linkend] = linkend
          @attrs[:resolved] = resolved if resolved
        end
      end

      class Citation < Base
        PM_TYPE = 'citation'

        def initialize(bibref:, **kwargs)
          super(**kwargs)
          @attrs[:bibref] = bibref
        end
      end

      # Register mark types for deserialization
      MARKS['emphasis'] = Emphasis
      MARKS['strong'] = Strong
      MARKS['italic'] = Italic
      MARKS['code'] = Code
      MARKS['link'] = Link
      MARKS['xref'] = Xref
      MARKS['citation'] = Citation
    end
  end
end