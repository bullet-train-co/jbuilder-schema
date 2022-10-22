# frozen_string_literal: true

require "active_support/core_ext/hash/deep_transform_values"

class Jbuilder::Schema
  VERSION = JBUILDER_SCHEMA_VERSION # See `jbuilder/schema/version.rb`

  module IgnoreSchemaMeta
    ::Jbuilder.prepend self

    def method_missing(*args, schema: nil, **options, &block) # standard:disable Style/MissingRespondToMissing
      super(*args, **options, &block)
    end
  end

  singleton_class.attr_accessor :components_path, :title_name, :description_name
  @components_path, @title_name, @description_name = "components/schemas", "title", "description"

  autoload :Resolver, "jbuilder/schema/resolver"
  autoload :Renderer, "jbuilder/schema/renderer"
  autoload :Template, "jbuilder/schema/template"

  class << self
    def configure
      yield self
    end

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

JbuilderSchema = ActiveSupport::Deprecation::DeprecatedConstantProxy.new "JbuilderSchema", "Jbuilder::Schema"
