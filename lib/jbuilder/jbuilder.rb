require 'jbuilder'

class Jbuilder
  alias_method :original_method_missing, :method_missing

  def initialize(options = {})
    @attributes = {schema: 'test'}

    @key_formatter = options.fetch(:key_formatter){ @@key_formatter ? @@key_formatter.clone : nil}
    @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)
    @deep_format_keys = options.fetch(:deep_format_keys, @@deep_format_keys)

    yield self if ::Kernel.block_given?
  end

  def method_missing(*args, &block)
    if args.present? && args.any? {  |e| e.is_a?(::Hash) && e.key?(:schema) }
      schema = args.extract! { |h| h.is_a?(::Hash) && h.key?(:schema) }.first[:schema]

      ::Rails.logger.info(schema)
    end
    original_method_missing(*args, &block)
  end
end