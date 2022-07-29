require "jbuilder/schema/handler"
require "jbuilder/schema/template"

module JbuilderSchema
  class Resolver < ::ActionView::FileSystemResolver

    def initialize
      super("app/views/api/v1")
    end

    def find_all(name, prefix = nil, partial = false)
      _find_all(name, prefix, partial)
    end

    private

    def _find_all(name, prefix, partial)
      path = ActionView::TemplatePath.build(name, prefix, partial)
      templates_from_path(path)
    end

    def templates_from_path(path)
      if path.name.include?(".")
        return []
      end

      # Instead of checking for every possible path, as our other globs would
      # do, scan the directory for files with the right prefix.
      paths = template_glob("#{escape_entry(path.to_s)}*")

      paths.map do |path|
        build_template(path)
      end
    end

    def build_template(template)
      parsed = @path_parser.parse(template.from(@path.size + 1))
      details = parsed.details
      source = source_for_template(template)

      JbuilderSchema::Template.new(JbuilderSchema::Handler)
    end
  end
end
