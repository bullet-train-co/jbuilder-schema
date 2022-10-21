# frozen_string_literal: true

require "jbuilder/schema/version"
require "jbuilder/schema/configuration"
require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

class Jbuilder::Schema
  class << self
    def yaml(path, **options)
      normalize(load(path, **options)).to_yaml
    end

    def json(path, **options)
      normalize(load(path, **options)).to_json
    end

    def load(path, format: nil, paths: ["app/views"], **options)
      source = Resolver.find_template_source(paths, path)
      Renderer.new(**options).render(source)&.schema! if source
    end

    private

    def normalize(schema)
      schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end
  end
end
