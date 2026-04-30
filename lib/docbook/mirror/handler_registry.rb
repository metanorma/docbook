# frozen_string_literal: true

module Docbook
  module Mirror
    # Registry mapping DocBook element classes to handler methods.
    #
    # Replaces the closed case/when dispatch in DocbookToMirror with an
    # open registry that supports third-party extension without modifying
    # core classes.
    #
    # Usage:
    #   registry = Docbook::Mirror.default_registry
    #   # Add a custom handler for a new element type
    #   registry.register(MyCustomElement, ->(el, ctx) { ... })
    #
    class HandlerRegistry
      Entry = Struct.new(:handler, :method_name, :concat, :extra_kwargs, keyword_init: true)

      def initialize
        @handlers = {}
      end

      # Register a handler for a DocBook element class.
      #
      # @param element_class [Class] the DocBook element class to handle
      # @param handler [Module, Class, Proc] the handler. If a Module/Class,
      #   must respond to the given method_name. If a Proc, called directly.
      # @param method_name [Symbol] method to call on handler (default: :call)
      # @param concat [Boolean] if true, handler result is an array to concat
      #   into the content array rather than a single item to append
      # @param extra_kwargs [Hash] additional keyword arguments to pass to the handler
      def register(element_class, handler, method_name: :call, concat: false, extra_kwargs: {})
        @handlers[element_class] = Entry.new(
          handler: handler,
          method_name: method_name,
          concat: concat,
          extra_kwargs: extra_kwargs
        )
      end

      # Find the handler entry for a given DocBook element.
      # @return [Entry, nil]
      def entry_for(element)
        @handlers[element.class]
      end

      # Check if a handler is registered for an element class.
      def registered?(element_class)
        @handlers.key?(element_class)
      end

      # Invoke the handler for a given element.
      # Returns [result, concat_flag] or nil if no handler registered.
      def handle(element, context:)
        entry = @handlers[element.class]
        return nil unless entry

        kwargs = { context: context }.merge(entry.extra_kwargs || {})

        result = case entry.handler
                 when Proc
                   entry.handler.call(element, context)
                 else
                   entry.handler.send(entry.method_name, element, **kwargs)
                 end

        [result, entry.concat]
      end
    end
  end
end
