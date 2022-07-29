require 'jbuilder'

class Jbuilder
  alias_method :original_method_missing, :method_missing


  def method_missing(*args, &block)
    if args.present? && args.any? {  |e| e.is_a?(::Hash) && e.key?(:schema) }
      schema = args.extract! { |h| h.is_a?(::Hash) && h.key?(:schema) }.first[:schema]

      ::Rails.logger.info(schema)
    end
    original_method_missing(*args, &block)
  end
end
#
# class JbuilderTemplate < Jbuilder
#   # class << self
#   #   attr_accessor :template_lookup_options
#   # end
#   #
#   # self.template_lookup_options = { handlers: [:jbuilder] }
#
#   def initialize(context, *args)
#     @context = context
#     @cached_root = nil
#
#     # ::Rails.logger.info(@context.inspect)
#     ::Rails.logger.info(args)
#
#     super(*args)
#   end
# end
#
# class JbuilderHandler
#   cattr_accessor :default_format
#   self.default_format = :json
#
#   def self.call(template, source = nil)
#     source ||= template.source
#     ::Rails.logger.info(source)
#     ::Rails.logger.info(self.inspect)
#
#     __already_defined = defined?(json)
#     json ||= JbuilderTemplate.new(self)
#     #{source}
#     #
#
#     ::Rails.logger.info(json)
#
#     json.target! unless (__already_defined && __already_defined != "method")
#   end
# end
