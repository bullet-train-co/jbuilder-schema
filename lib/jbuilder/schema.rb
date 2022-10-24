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

  autoload :Renderer, "jbuilder/schema/renderer"

  class << self
    def configure
      yield self
    end

    def yaml(object = nil, **options)
      normalize(load(object, **options)).to_yaml
    end

    def json(object = nil, **options)
      normalize(load(object, **options)).to_json
    end

    def load(object = nil, paths: ["app/views"], title: nil, description: nil, **options)
      options.merge! partial: object.to_partial_path, object: object if object
      (options[:locals] ||= {})[:__jbuilder_schema_options] = { model: object&.class, title: title, description: description }
      Renderer.new(paths).render(**options)
    end

    private

    def normalize(schema)
      schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end
  end
end
