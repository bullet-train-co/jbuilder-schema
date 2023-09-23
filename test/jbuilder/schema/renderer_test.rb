# frozen_string_literal: true

require "test_helper"

class Jbuilder::Schema::RendererTest < ActiveSupport::TestCase
  setup do
    I18n.backend.store_translations "en",
      users: {
        title: "User",
        description: "User in the blog",
        fields: {
          id: {description: "User ID"},
          name: {description: "User Name"},
          email: {description: "User Email"},
          created_at: {description: "User Creation Date"},
          updated_at: {description: "User Update Date"}
        }
      },
      articles: {fields: {
        id: {description: "Article ID"},
        status: {description: "Article Status"},
        title: {description: "Article Title"},
        body: {description: "Article Body"},
        created_at: {description: "Article Creation Date"},
        updated_at: {description: "Article Update Date"},
        author: {description: "Article Author"},
        ratings: {description: "Article Ratings"},
        comments: {description: "Article Comments"}
      }}

    @user = User.first
    @article = @user.articles.first

    @user_schema = YAML.load_file(file_fixture("schemas/user.yaml"))
    @article_schema = YAML.load_file(file_fixture("schemas/article.yaml"))

    @renderer = Jbuilder::Schema.renderer(%w[test/fixtures/app/views/api/v1 test/fixtures/app/views], locals: {current_user: @user})
  end

  teardown { I18n.reload! }

  test "renders with default renderer" do
    Dir.chdir("./test/fixtures") do
      schema = Jbuilder::Schema.yaml @user
      assert_equal @user_schema.to_yaml, schema
    end
  end

  test "renders a template with view assigns" do
    Dir.chdir("./test/fixtures") do
      schema = Jbuilder::Schema.render template: "articles/index", assigns: {articles: Article.all}

      assert_equal({
        type: :array,
        items: {
          "id" => {type: :integer},
          "title" => {type: :string}
        },
        example: [
          {"id" => 1, "title" => "Generic title 0"},
          {"id" => 2, "title" => "Generic title 1"},
          {"id" => 3, "title" => "Generic title 2"}
        ]
      }, schema)
    end
  end

  test "renders a schema from a fixture" do
    schema = @renderer.render @article, title: "Article", description: "Article in the blog"
    schema = schema.deep_transform_values { |v| (v == /\w+/) ? "\\w+" : v }
    schema = schema.deep_transform_keys(&:to_s).deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
    assert_equal @article_schema, schema
  end

  test "renders a schema from a fixture to yaml" do
    schema = @renderer.yaml(@article, title: "Article", description: "Article in the blog")
    assert_equal @article_schema.to_yaml, schema
  end

  test "renders a schema from a fixture to json" do
    schema = @renderer.json @article, title: "Article", description: "Article in the blog"
    assert_equal JSON.parse(@article_schema.to_json, symbolize_names: true), JSON.parse(schema, symbolize_names: true)
  end
end
