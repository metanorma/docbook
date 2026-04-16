# frozen_string_literal: true

require_relative "base"

module Docbook
  module Mirror
    module Mark
      # Link mark - represents both internal (linkend) and external (href) links
      class Link < Base
        PM_TYPE = "link"

        def initialize(href: nil, linkend: nil, **)
          super(**)
          @attrs[:href] = href if href
          @attrs[:linkend] = linkend if linkend
        end

        def href
          @attrs[:href]
        end

        def linkend
          @attrs[:linkend]
        end
      end

      # Xref mark - cross-reference with resolved title
      class Xref < Base
        PM_TYPE = "xref"

        def initialize(linkend:, resolved: nil, **)
          super(**)
          @attrs[:linkend] = linkend
          @attrs[:resolved] = resolved if resolved
        end

        def linkend
          @attrs[:linkend]
        end

        def resolved
          @attrs[:resolved]
        end
      end

      # Citation mark for bibliography references
      class Citation < Base
        PM_TYPE = "citation"

        def initialize(bibref:, **)
          super(**)
          @attrs[:bibref] = bibref
        end

        def bibref
          @attrs[:bibref]
        end
      end
    end
  end
end
