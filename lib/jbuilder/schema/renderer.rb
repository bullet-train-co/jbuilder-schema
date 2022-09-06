# frozen_string_literal: true

require "jbuilder/schema/template"
require "jbuilder/schema/handler"
# TODO: Find a better way to load main app's helpers:
# Helpers don't work in Jbuilder itself, so no need to include them here!
# ActionController::Base.all_helpers_from_path('app/helpers').each { |helper| require "./app/helpers/#{helper}_helper" }

module JbuilderSchema
  # Here we initialize all the variables needed for template and pass them to it
  class Renderer
    # TODO: Find a better way to load main app's helpers:
    # Helpers don't work in Jbuilder itself, so no need to include them here!
    # ActionController::Base.all_helpers_from_path('app/helpers').each { |helper| include Object.const_get("::#{helper.camelize}Helper") }

    attr_reader :model

    def initialize(locals)
      # OPTIMIZE: Not sure if we need this
      ActionView::Template.register_template_handler :jbuilder, JbuilderSchema::Handler

      _define_locals!(locals)
    end

    def render(source)
      JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
        # TODO: Get rid of 'eval'
        eval source.to_s # standard:disable Security/Eval
      end
    end

    def method_missing(method, *args)
      if method.to_s.end_with?("_path", "_url")
        # For cases like 'article_url(article)'
        # Not sure if we should really generate urls here, if so we can use something like
        #   ::Rails.application.routes.url_helpers.send(method, *args, only_path: true)
        method.to_s
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?("_path", "_url") || super
    end

    private

    def _define_locals!(locals)
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
