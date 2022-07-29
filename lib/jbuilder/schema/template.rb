require 'jbuilder/jbuilder_template'

module JbuilderSchema
  class Template < ::JbuilderTemplate
    class << self
      attr_accessor :template_lookup_options
    end

    self.template_lookup_options = { handlers: [:jbuilder] }

    def initialize(context, options = {})
      @context = context
      @cached_root = nil

      @attributes = {}

      # @key_formatter = options.fetch(:key_formatter){ @@key_formatter ? @@key_formatter.clone : nil}
      # @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)
      # @deep_format_keys = options.fetch(:deep_format_keys, @@deep_format_keys)

      yield self if ::Kernel.block_given?
    end

    def target
      @attributes
    end
  end
end
