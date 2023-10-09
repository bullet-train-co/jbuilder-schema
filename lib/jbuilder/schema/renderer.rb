require "active_support/core_ext/hash/deep_transform_values"
require_relative "template"

class Jbuilder::Schema::Renderer
  @@view_renderer = ActionView::Base.with_empty_template_cache
  @@view_renderer.prefix_partial_path_with_controller_namespace = false

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
    @view_renderer.assign assigns if assigns

    partial_path = %i[to_partial_path_for_jbuilder_schema to_partial_path].map { object.public_send(_1) if object.respond_to?(_1) }.compact.first
    if partial_path
      options[:partial] = partial_path
      options[:object] = object
    end

    json = if partial_path
      original_render(options.dup, options.dup)
    else
      original_render(object || options.dup, options.dup)
    end

    options[:locals] ||= {}
    options[:locals].merge! @default_locals if @default_locals
    options[:locals][:__jbuilder_schema_options] = {json: json, object: object, title: title, description: description}

    @view_renderer.render(options).then do |result|
      result.respond_to?(:unwrap_target!) ? result.unwrap_target! : result
    end
  end

  # Thin wrapper around the regular Jbuilder JSON output render, which also parses it into a hash.
  def original_render(options = {}, locals = {})
    JSON.parse @view_renderer.render(options, locals)
  end

  private

  def normalize(schema)
    schema.deep_stringify_keys
      .deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
      .deep_transform_values { |v| v.is_a?(Regexp) ? v.source : v }
  end
end
