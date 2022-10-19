# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    attr_reader :path, :template, :model, :locals, :format, :paths

    def initialize(path, model:, format: nil, paths: ["app/views"], locals: {}, **options)
      @path = path
      @model = model
      @locals = locals
      @format = format
      @paths = paths

      @template = Renderer.new(locals: locals, **options).render(_find_template)
    end

    def schema!
      template&.schema!
    end

    private

    def _find_template
      prefix, controller, action, partial = _resolve_path
      paths.each do |path|
        found = Resolver.new("#{path}/#{prefix}").find_all(action, controller, partial)
        return found if found
      end
    end

    def _resolve_path
      *prefixes, controller, action = path.split("/")
      partial = true if action.delete_prefix! "_"

      [prefixes.join("/"), controller, action, partial]
    end
  end
end
