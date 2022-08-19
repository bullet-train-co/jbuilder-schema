# frozen_string_literal: true

require "jbuilder/schema/version"
require "jbuilder/schema/builder"

module JbuilderSchema
  def jbuilder_schema(path, **options)
    JbuilderSchema::Builder.new(path, **options).schema!
  end
end
