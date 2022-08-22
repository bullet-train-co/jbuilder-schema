# frozen_string_literal: true

require "jbuilder/schema/template"

module JbuilderSchema
  # TBH Have no idea why we need this
  class Handler
    class_attribute :default_format
    self.default_format = :json

    def self.call(template, source = nil)
      source ||= template.source

      # # ::Rails.logger.info(source)
      #
      # __already_defined = defined?(json)
      #
      # JbuilderSchema::Template.new(self)
      #
      # # json ||= JbuilderSchema::Template.new(self)
      # #
      # source
      # # #
      # # json.target! unless (__already_defined && __already_defined != "method")
      # #

      # this juggling is required to keep line numbers right in the error
      %{__already_defined = defined?(json); json||=JbuilderSchema::Template.new(self); #{source}
      json.target! unless (__already_defined && __already_defined != "method")}
    end

    def self.handles_encoding?
      true
    end
  end
end
