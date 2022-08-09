# frozen_string_literal: true

require "jbuilder/schema/resolver"

module JbuilderSchema
  # Helpers to build json-schema
  module Helpers
    def jbuilder_schema(path, title = "", description = "")
      @template ||= _resolve(path)
      return {} unless @template

      _set_meta title, description
      _set_properties @template.properties
      _set_required @template.required

      _object
    end

    private

    def _object
      @object ||= {
        type: :object,
        title: "",
        description: "",
        links: [],
        required: [],
        properties: {}
      }
    end

    def _set_meta(title = "", description = "")
      _object[:title] = title
      _object[:description] = description
    end

    def _set_properties(properties)
      _object[:properties].merge! properties
    end

    def _set_required(properties)
      _object[:required] = properties # if properties.any?
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

      [prefix, controller, action, partial]
    end
  end
end
