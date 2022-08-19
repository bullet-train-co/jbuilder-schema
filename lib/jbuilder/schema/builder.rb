# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :path, :template, :model, :title, :description, :locals

    def initialize(path, **options)
      @path = path
      # TODO: Need this for `required`, make it simpler:
      @model = options[:model]
      @title = options[:title]
      @description = options[:description]
      @locals = options[:locals] || {}
      @template = _render_template
    end

    def schema!
      return {} unless template

      _schema
    end

    private

    def _schema
      { type: template.type }.merge(template.type == :object ? _object : _array)
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

    def _render_template
      JbuilderSchema::Renderer.new(locals).render(_find_template)
    end

    def _create_required!
      # OPTIMIZE: It might be that there could be several models in required field, need to learn more about it.
      # Here's the code for that case:
      # models.flat_map { |model|
      #   model.validators.grep(ActiveRecord::Validations::PresenceValidator).flat_map(&:attributes)
      # }.unshift(:id).select { |attribute| template.attributes.keys.include?(attribute) }
      model.validators.grep(ActiveRecord::Validations::PresenceValidator)
           .flat_map(&:attributes).unshift(:id)
           .select { |attribute| template.attributes.keys.include?(attribute) }
    end
  end
end
