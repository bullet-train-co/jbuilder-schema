# frozen_string_literal: true

require "jbuilder/schema/builder"

module JbuilderSchema
  # Helpers to build json-schema
  module Helpers
    def jbuilder_schema(path, **options)
      JbuilderSchema::Builder.new(path, **options).schema!
    end
  end
end
