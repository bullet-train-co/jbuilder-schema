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

  def render(object = nil, title: nil, description: nil, assigns: nil, **options)
    json = original_render(object, assigns: assigns, **options)

    options = process_options(object, options)
    options[:locals][:__jbuilder_schema_options] = { json: json, object: object, title: title, description: description }

    @view_renderer.render(options)
  end

  # Renders the plain Jbuilder JSON output and parses it.
  def original_render(object = nil, assigns: nil, **options)
    @view_renderer.assign assigns if assigns
    JSON.parse @view_renderer.render(process_options(object, options))
  end

  private

  def normalize(schema)
    schema.deep_stringify_keys
      .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
      .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
  end

  def process_options(object, options)
    if object
      partial_path = object.respond_to?(:to_partial_path_for_jbuilder_schema) ? object.to_partial_path_for_jbuilder_schema : object.to_partial_path
      options.merge! partial: partial_path, object: object
    end

    options[:locals] ||= {}
    options[:locals].merge! @default_locals if @default_locals
    options
  end
end
