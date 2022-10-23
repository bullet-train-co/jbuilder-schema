require "test_helper"

class Jbuilder::PatchTest < ActiveSupport::TestCase
  test "plain jbuilder ignores passed schema" do
    json = Jbuilder.new
    json.something true, schema: {type: :boolean, description: "ain't this nice?"}

    assert_equal({something: true}, JSON.parse(json.target!, symbolize_names: true))
  end
end
