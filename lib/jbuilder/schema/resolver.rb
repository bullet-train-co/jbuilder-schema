# frozen_string_literal: true

require "jbuilder/schema/template"

class Jbuilder::Schema
  # Resolver finds and returns Jbuilder template.
  # It basically inherits from ActionView::FileSystemResolver as it does all the job for us.
  # We're just building our own template in the end of the search.
  class Resolver < ::ActionView::FileSystemResolver
    def self.find_template_source(paths, path)
      *prefixes, controller, action = path.split("/")
      prefix = prefixes.join("/")
      partial = true if action.delete_prefix! "_"

      paths.find do |path|
        found = new("#{path}/#{prefix}").find(action, controller, partial)
        return found if found
      end
    end

    def find(name, prefix = nil, partial = false)
      path = ActionView::TemplatePath.build(name, prefix, partial)
      template_source_from_path path unless path.name.include?(".")
    end

    private

    def template_source_from_path(path)
      # Instead of checking for every possible path, as our other globs would
      # do, scan the directory for files with the right prefix.
      source_for_template template_glob("#{escape_entry(path.to_s)}*").first
    end
  end
end
