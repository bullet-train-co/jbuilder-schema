# frozen_string_literal: true

require "jbuilder/schema/version"
require "jbuilder/schema/configuration"
require "jbuilder/schema/resolver"
require "jbuilder/schema/renderer"

# Main gem module with configuration and helper methods
module JbuilderSchema
  def jbuilder_schema(path, format: nil, paths: ["app/views"], **options)
    source = Resolver.find_template_source(paths, path)
    schema = Renderer.new(**options).render(source)&.schema! if source

    if schema && format
      Serializer.serialize(schema, format).html_safe
    else
      schema
    end
  end

  module Serializer
    def self.serialize(schema, format)
      case format
      when :yaml then normalize(schema).to_yaml
      when :json then normalize(schema).to_json
      end
    end

    def self.normalize(schema)
      schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end
  end
end
