# frozen_string_literal: true

require "jbuilder/schema/version"
require "jbuilder/schema/configuration"
require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

class Jbuilder::Schema
  class << self
    def render(path, format: nil, paths: ["app/views"], **options)
      source = Resolver.find_template_source(paths, path)
      schema = Renderer.new(**options).render(source)&.schema! if source
      schema = serialize(schema, format).html_safe if schema && format
      schema
    end

    private

    def serialize(schema, format)
      case format
      when :yaml then normalize(schema).to_yaml
      when :json then normalize(schema).to_json
      end
    end

    def normalize(schema)
      schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end
  end
end
