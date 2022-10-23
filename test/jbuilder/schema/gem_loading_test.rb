require "test_helper"

class Jbuilder::Schema::GemLoadingTest < ActiveSupport::TestCase
  test "loads when put after jbuilder" do
    output = `bundle exec ruby test/fixtures/gem_loading_script.rb`

    assert_includes output, "type: object"
    assert_includes output, "properties:\n  id:\n    type: integer"
  end
end
