# frozen_string_literal: true

require "jbuilder/schema/template"

module JbuilderSchema
  # Resolver finds and returns Jbuilder template.
  # It basically inherits from ActionView::FileSystemResolver as it does all the job for us.
  # We're just building our own template in the end of the search.
  class Resolver < ::ActionView::FileSystemResolver
    attr_reader :template

    def initialize(path)
      super("app/views/#{path}")
    end

    def find_all(name, prefix = nil, partial = false)
      _find_all(name, prefix, partial)
    end

    private

    def _find_all(name, prefix, partial)
      path = ActionView::TemplatePath.build(name, prefix, partial)
      templates_from_path(path).first
    end

    def templates_from_path(path)
      return [] if path.name.include?(".")

      # Instead of checking for every possible path, as our other globs would
      # do, scan the directory for files with the right prefix.
      paths = template_glob("#{escape_entry(path.to_s)}*")

      paths.map do |path|
        _source(path)
      end
    end

    def _source(template)
      source_for_template(template).to_s
    end
  end
end
