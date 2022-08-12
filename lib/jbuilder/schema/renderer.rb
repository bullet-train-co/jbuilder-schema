# frozen_string_literal: true

require 'jbuilder/schema/template'
require 'jbuilder/schema/handler'

module JbuilderSchema
  # Here we initialize all the variables needed for template and pass them to it
  class Renderer
    def initialize(locals)
      ActionView::Template.register_template_handler :jbuilder, JbuilderSchema::Handler

      locals.each { |k, v| define_singleton_method(k) {v } }
    end

    def render(source)
      JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
        # TODO: Get rid of 'eval'
        eval source.to_s
      end
    end

    def method_missing method, *args
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        # For cases like 'article_url(article)'
        # Not sure if we should really generate urls here, if so we can use something like
        #   ::Rails.application.routes.url_helpers.send(method, *args, only_path: true)
        "#{method}"
      else
        super
      end
    end
  end
end