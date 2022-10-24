require_relative "template"

class Jbuilder::Schema::Renderer
  @@view_renderer = ActionView::Base.with_empty_template_cache

  def initialize(paths)
    @view_renderer = @@view_renderer.with_view_paths(paths)
  end

  def render(**options)
    @view_renderer.render(options)
  end
end
