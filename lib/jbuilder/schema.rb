# frozen_string_literal: true

require "jbuilder/schema/version"
require "jbuilder/schema/configuration"
require "jbuilder/schema/builder"

# Main gem module with configuration and helper methods
module JbuilderSchema
  def jbuilder_schema(path, **options)
    Builder.new(path, **options).schema!
  end

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
