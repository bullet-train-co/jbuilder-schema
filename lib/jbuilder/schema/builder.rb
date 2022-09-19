# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :path, :template, :model, :title, :description, :locals, :format, :paths

    def initialize(path, **options)
      @path = path
      # TODO: Need this for `required`, make it simpler:
      @model = options[:model]
      @title = options[:title]
      @description = options[:description]
      @locals = options[:locals] || {}
      @format = options[:format]
      @paths = options[:paths] || ["app/views"]
      @template = _render_template
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
      {type: template.type}.merge(template.type == :object ? _object : _array)
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

    def _object
      {
        title: title,
        description: description,
        required: _create_required!,
        properties: template.attributes
      }
    end

    def _array
      template.attributes
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

    def _render_template
      Renderer.new(locals, model: model).render(_find_template)
    end

    def _create_required!
      # OPTIMIZE: It might be that there could be several models in required field, need to learn more about it.
      template.attributes.keys.select { |attribute|
        model.validators.grep(::ActiveRecord::Validations::PresenceValidator)
          .flat_map(&:attributes).unshift(:id)
          .include?(attribute.to_s.underscore.to_sym)
      }.uniq
    end
  end
end
