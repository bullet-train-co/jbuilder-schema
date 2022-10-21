# frozen_string_literal: true

require "jbuilder/schema/template"
# TODO: Find a better way to load main app's helpers:
# Helpers don't work in Jbuilder itself, so no need to include them here!
# ActionController::Base.all_helpers_from_path('app/helpers').each { |helper| require "./app/helpers/#{helper}_helper" }

class Jbuilder::Schema
  # Here we initialize all the variables needed for template and pass them to it
  class Renderer
    # TODO: Find a better way to load main app's helpers:
    # Helpers don't work in Jbuilder itself, so no need to include them here!
    # ActionController::Base.all_helpers_from_path('app/helpers').each { |helper| include Object.const_get("::#{helper.camelize}Helper") }

    attr_reader :locals, :options

    def initialize(locals: {}, **options)
      @locals = locals
      @options = options
      _define_locals!
    end

    def render(source)
      Template.new(**options) do |json|
        # TODO: Get rid of 'eval'
        eval source.to_s # standard:disable Security/Eval
      end
    end

    def method_missing(method, *args)
      if method.to_s.end_with?("_path", "_url")
        method.to_s
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?("_path", "_url") || super
    end

    private

    def _define_locals!
      locals.each do |k, v|
        # Setting instance variables (`@article`):
        instance_variable_set("@#{k}", v)

        # Setting local variables (`article`):
        # We can define method:
        # define_singleton_method(k) { v }
        # or set attr_reader on an instance, this feels better:
        singleton_class.instance_eval { attr_reader k }
      end
    end
  end
end
