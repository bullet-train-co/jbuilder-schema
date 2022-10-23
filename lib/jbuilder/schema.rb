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

  autoload :Template, "jbuilder/schema/template"

  ActiveSupport.on_load :action_view do
    ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
  end

  require "jbuilder/jbuilder_template" # Hack to load ::JbuilderHandler.

  class JbuilderHandler < ::JbuilderHandler
    def self.call(template, source = nil)
      super.sub("JbuilderTemplate", "Jbuilder::Schema::Template").sub("target!", "schema!") # lol
    end
  end

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

    @@view_renderer = ActionView::Base.with_empty_template_cache

    def load(object = nil, paths: ["app/views"], title: nil, description: nil, **options)
      $jbuilder_details = { model: object&.class, title: title, description: description }

      options.merge! partial: object.to_partial_path, object: object if object
      @@view_renderer.with_view_paths(paths).render(**options)
    ensure
      $jbuilder_details = nil
    end

    private

    def normalize(schema)
      schema.deep_stringify_keys
        .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
    end
  end
end
