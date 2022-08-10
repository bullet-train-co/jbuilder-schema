# frozen_string_literal: true

require "jbuilder/schema/resolver"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :template, :title, :description

    def initialize(path, title: "", description: "")
      @template = _resolve(path)
      @title = title
      @description = description
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
        links: [],
        required: template.required,
        properties: template.properties
      }
    end

    def _resolve(path)
      prefix, controller, action, partial = _resolve_path(path)
      JbuilderSchema::Resolver.new(prefix).find_all(action, controller, partial)
    end

    def _resolve_path(path)
      action = path.split("/").last
      controller = path.split("/")[-2]
      prefix = path.delete_suffix("/#{controller}/#{action}")
      partial = action[0] == "_"

      action.delete_prefix!("_") if action[0] == "_"

      [prefix, controller, action, partial]
    end
  end
end
