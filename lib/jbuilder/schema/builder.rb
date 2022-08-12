# frozen_string_literal: true

require "jbuilder/schema/handler"
require "jbuilder/schema/resolver"
require "jbuilder/schema/template"
require "jbuilder/schema/executor"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    # include ActionController::Helpers
    attr_reader :path, :template, :title, :description, :locals

    def initialize(path, **options)
      ActionView::Template.register_template_handler :jbuilder, JbuilderSchema::Handler

      @path = path
      @title = options[:title]
      @description = options[:description]
      @locals = options[:locals] || {}
      @template = _build_template
    end

    def schema!
      return {} unless template

      _object
    end

    private

    def _object
      {
        type: :object,
        title: title,
        description: description,
        required: template.required,
        properties: template.properties
      }
    end

    def _find_template
      prefix, controller, action, partial = _resolve_path
      JbuilderSchema::Resolver.new(prefix).find_all(action, controller, partial)
    end

    def _resolve_path
      action = path.split("/").last
      controller = path.split("/")[-2]
      prefix = path.delete_suffix("/#{controller}/#{action}")
      partial = action[0] == "_"

      action.delete_prefix!("_") if action[0] == "_"

      [prefix, controller, action, partial]
    end

    def _build_template
      JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
        JbuilderSchema::Executor.new(locals).exec(eval("lambda { #{_find_template} }"))
      end
    end
  end
end
