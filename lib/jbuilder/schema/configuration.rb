# frozen_string_literal: true

# Configuration
module JbuilderSchema
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  # Configuration class with defaults
  class Configuration
    attr_accessor :components_path, :description_name

    def initialize
      @components_path = "components/schemas"
      @description_name = "description"
    end
  end
end
