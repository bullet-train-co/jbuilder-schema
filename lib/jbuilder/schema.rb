# frozen_string_literal: true

require "jbuilder"
require "jbuilder/schema/version"
require "active_support/core_ext/module/delegation"

class Jbuilder::Schema
  VERSION = JBUILDER_SCHEMA_VERSION # See `jbuilder/schema/version.rb`

  module IgnoreSchemaMeta
    ::Jbuilder.prepend self

    def method_missing(*args, schema: nil, **options, &block) # standard:disable Style/MissingRespondToMissing
      super(*args, **options, &block)
    end

    def set!(*args, schema: nil, **options, &block)
      super(*args, **options, &block)
    end

    def array!(*args, schema: nil, **options, &block)
      super(*args, **options, &block)
    end

    def extract!(*args, schema: nil, **options, &block)
      super(*args, **options, &block)
    end
  end

  singleton_class.alias_method :configure, :tap
  singleton_class.attr_accessor :components_path, :title_name, :description_name
  @components_path, @title_name, @description_name = "components/schemas", "title", "description"

  autoload :Renderer, "jbuilder/schema/renderer"

  def self.renderer(paths = nil, locals: nil)
    if paths.nil? && locals.nil?
      @renderer ||= Renderer.new("app/views")
    else
      Renderer.new(paths, locals)
    end
  end
  singleton_class.delegate :yaml, :json, :render, to: :renderer
end
