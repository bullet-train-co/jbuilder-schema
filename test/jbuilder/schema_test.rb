# frozen_string_literal: true

require "test_helper"

class Jbuilder::SchemaTest < ActiveSupport::TestCase
  test "version" do
    refute_nil Jbuilder::Schema::VERSION
  end
end
