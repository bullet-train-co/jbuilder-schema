# frozen_string_literal: true

module JbuilderSchema
  # Configuration class with defaults
  class Configuration
    attr_accessor :components_path, :description_name

    def initialize
      @components_path = "components/schemas"
      @description_name = "description"
    end
  end
end
