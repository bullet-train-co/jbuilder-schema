# frozen_string_literal: true

# Configuration
class Jbuilder::Schema
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  # Configuration class with defaults
  class Configuration
    attr_accessor :components_path, :title_name, :description_name

    def initialize
      @components_path = "components/schemas"
      @title_name = "title"
      @description_name = "description"
    end
  end
end
