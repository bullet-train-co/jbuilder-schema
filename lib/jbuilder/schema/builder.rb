# frozen_string_literal: true

require "jbuilder/schema/resolver"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :path, :template, :title, :description, :locals

    def initialize(path, **options)
      @path = path
      @template = _find_template
      @title = options[:title]
      @description = options[:description]
      @locals = options[:locals] || {}
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
  end
end
