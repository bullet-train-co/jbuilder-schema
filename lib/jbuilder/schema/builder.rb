# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    def initialize(path, paths: ["app/views"], **options)
      @path = path
      @paths = paths
      @template = Renderer.new(**options).render(_find_template)
    end

    def schema!
      @template&.schema!
    end

    private

    def _find_template
      *prefixes, controller, action = @path.split("/")
      prefix = prefixes.join("/")
      partial = true if action.delete_prefix! "_"

      @paths.each do |path|
        found = Resolver.new("#{path}/#{prefix}").find(action, controller, partial)
        return found if found
      end
    end
  end
end
