# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :path, :template, :model, :locals, :format, :paths

    def initialize(path, **options)
      @path = path
      # TODO: Need this for `required`, make it simpler:
      @model = options[:model]
      @locals = options[:locals] || {}
      @format = options[:format]
      @paths = options[:paths] || ["app/views"]
      @template = _render_template(**options)
    end

    def schema!
      return {} unless template

      case format
      when :yaml
        _yaml_schema
      when :json
        _json_schema
      else
        _schema
      end
    end

    private

    def _schema
      template.schema!
    end

    def _stringified_schema
      _schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end

    def _yaml_schema
      YAML.dump(_stringified_schema).html_safe
    end

    def _json_schema
      JSON.dump(_stringified_schema).html_safe
    end

    def _find_template
      prefix, controller, action, partial = _resolve_path
      found = nil
      paths.each do |path|
        found = Resolver.new("#{path}/#{prefix}").find_all(action, controller, partial)
        break if found
      end
      found
    end

    def _resolve_path
      action = path.split("/").last
      controller = path.split("/")[-2]
      prefix = path.delete_suffix("/#{controller}/#{action}")
      partial = action[0] == "_"

      action.delete_prefix!("_") if action[0] == "_"

      [prefix, controller, action, partial]
    end

    def _render_template(**options)
      Renderer.new(**options).render(_find_template)
    end
  end
end
