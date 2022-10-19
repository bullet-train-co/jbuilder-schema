# frozen_string_literal: true

require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

module JbuilderSchema
  # Class that builds schema object from path
  class Builder
    def initialize(path, paths: ["app/views"], **options)
      source = Resolver.find_template_source(paths, path)
      @template = Renderer.new(**options).render(source)
    end

    def schema!
      @template&.schema!
    end
  end
end
