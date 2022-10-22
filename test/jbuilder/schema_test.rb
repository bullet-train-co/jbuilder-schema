# frozen_string_literal: true

require "test_helper"

class SchemaTest < ActiveSupport::TestCase
  test "version" do
    refute_nil Jbuilder::Schema::VERSION
  end

  test "deprecated old name" do
    assert_deprecated { JbuilderSchema.components_path }
  end
end
