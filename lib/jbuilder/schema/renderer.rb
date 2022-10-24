require "active_support/core_ext/hash/deep_transform_values"
require_relative "template"

class Jbuilder::Schema::Renderer
  @@view_renderer = ActionView::Base.with_empty_template_cache

  def initialize(paths, default_locals = nil)
    @view_renderer = @@view_renderer.with_view_paths(paths)
    @default_locals = default_locals
  end

  def yaml(...)
    normalize(render(...)).to_yaml
  end

  def json(...)
    normalize(render(...)).to_json
  end

  def render(object = nil, title: nil, description: nil, **options)
    options.merge! partial: object.to_partial_path, object: object if object

    options[:locals] ||= {}
    options[:locals].merge! @default_locals if @default_locals
    options[:locals][:__jbuilder_schema_options] = { model: object&.class, title: title, description: description }

    @view_renderer.render(options)
  end

  private

  def normalize(schema)
    schema.deep_stringify_keys
      .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
      .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
  end
end
