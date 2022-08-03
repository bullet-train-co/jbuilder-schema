require "jbuilder"

class Jbuilder
  alias_method :original_method_missing, :method_missing

  def initialize(options = {})
    ::Rails.logger.info(">> OPTIONS:")
    ::Rails.logger.info(options)

    ::Rails.logger.info(">> SELF1:")
    ::Rails.logger.info(inspect)

    ::Rails.logger.info(">> CONTEXT:")
    ::Rails.logger.info(@context)

    @attributes = {}

    @key_formatter = options.fetch(:key_formatter) { @@key_formatter ? @@key_formatter.clone : nil }
    @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)
    @deep_format_keys = options.fetch(:deep_format_keys, @@deep_format_keys)

    yield self if ::Kernel.block_given?
  end

  def method_missing(*args, &block)
    if args.present? && args.any? { |e| e.is_a?(::Hash) && e.key?(:schema) }
      schema = args.extract! { |h| h.is_a?(::Hash) && h.key?(:schema) }.first[:schema]

      ::Rails.logger.info(">> SELF2:")
      ::Rails.logger.info(self)
      ::Rails.logger.info(">> ARGS:")
      ::Rails.logger.info(args)
      ::Rails.logger.info(">> BLOCK:")
      ::Rails.logger.info(block)
    end
    original_method_missing(*args, &block)
  end
end

class JbuilderTemplate < Jbuilder
  # class << self
  #   attr_accessor :template_lookup_options
  # end
  #
  # self.template_lookup_options = { handlers: [:jbuilder] }

  def initialize(context, *args)
    ::Rails.logger.info(">>JbuilderTemplate")
    # @context = context
    # @cached_root = nil
    #
    # ::Rails.logger.info(@context.inspect)
    # ::Rails.logger.info(args)
    #
    # # super(*args)
  end

  private

  def _render_partial(options)
    ::Rails.logger.info("_render_partial:")
    ::Rails.logger.info(options)
    ::Rails.logger.info(@context.inspect)
    ::Rails.logger.info(self)

    options[:locals][:json] = self
    @context.render options
  end
end

class JbuilderHandler
  cattr_accessor :default_format
  self.default_format = :json

  # def self.call(template, source = nil)
  #   ::Rails.logger.info('JbuilderHandler')
  #   ::Rails.logger.info(template.context.inspect)
  #   source ||= template.source
  #   ::Rails.logger.info(source)
  #   ::Rails.logger.info(self.inspect)
  #
  #   __already_defined = defined?(json)
  #   json ||= JbuilderTemplate.new(self)
  #   #{source}
  #   #
  #
  #   ::Rails.logger.info(json)
  #
  #   json.target! unless (__already_defined && __already_defined != "method")
  # end
  def self.call(template, source = nil)
    source ||= template.source

    ::Rails.logger.info(">>JbuilderHandler")
    ::Rails.logger.info(self)
    # puts ">>SELF #{self}"

    # this juggling is required to keep line numbers right in the error
    %{__already_defined = defined?(json); json||=JbuilderTemplate.new(self); #{source}
      json.target! unless (__already_defined && __already_defined != "method")}
  end
end
