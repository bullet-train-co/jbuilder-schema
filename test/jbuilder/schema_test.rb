require "test_helper"

class SchemaTest < ActiveSupport::TestCase
  test "version" do
    refute_nil JbuilderSchema::VERSION
  end
end
