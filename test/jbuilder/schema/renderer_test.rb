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
          public_id: {description: "User Public ID"},
          name: {description: "User Name"},
          email: {description: "User Email"},
          created_at: {description: "User Creation Date"},
          updated_at: {description: "User Update Date"},
          articles: {description: "User Articles"},
          comments: {description: "User Comments"}
        }
      },
      articles: {fields: {
        id: {description: "Article ID"},
        public_id: {description: "Article Public ID"},
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
          type: :object,
          title: "Translation missing: en.title",
          description: "Translation missing: en.description",
          required: ["id"],
          properties: {
            "id" => {type: :integer},
            "title" => {type: [:string, "null"]}
          }
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

  test "renders a template with custom translation keys" do
    original_title_name = Jbuilder::Schema.title_name
    original_description_name = Jbuilder::Schema.description_name

    Jbuilder::Schema.configure do |config|
      config.title_name = ["api_title", "title"]
      config.description_name = ["api_description", "heading"]
    end

    Dir.chdir("./test/fixtures") do
      schema = Jbuilder::Schema.render(@user)
      schema.deep_symbolize_keys!

      # will find title key via a fallback
      assert_equal "User", schema[:title]

      # will not find any description keys
      assert_equal "Translation missing: en.users.api_description", schema[:description]
      assert_equal "Translation missing: en.users.fields.id.api_description", schema[:properties][:id][:description]
    end
  ensure
    Jbuilder::Schema.configure do |config|
      config.title_name = original_title_name
      config.description_name = original_description_name
    end
  end
end
