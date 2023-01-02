# frozen_string_literal: true

require "test_helper"

class Jbuilder::Schema::BuilderTest < ActiveSupport::TestCase
  setup do
    I18n.backend.store_translations "en", articles: {fields: {
      id: {description: "en.articles.fields.id.description"},
      status: {description: "en.articles.fields.status.description"},
      title: {description: "en.articles.fields.title.description"},
      body: {description: "en.articles.fields.body.description"},
      created_at: {description: "en.articles.fields.created_at.description"},
      updated_at: {description: "en.articles.fields.updated_at.description"}
    }}

    @user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    @article = Article.new(id: 1, user: @user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    @renderer = Jbuilder::Schema.renderer("test/fixtures/api/v1", locals: { current_user: @user })
  end

  teardown { I18n.reload! }

  test "renderers with default renderer" do
    I18n.backend.store_translations "en", users: {
      title: "User title",
      description: "User in the blog",
      fields: {
        id: {description: "en.users.fields.id.description"},
        name: {description: "en.users.fields.name.description"},
      }
    }

    Dir.chdir("./test/fixtures") do
      schema = Jbuilder::Schema.yaml @user

      assert_equal <<~YAML, schema
        ---
        type: object
        title: User title
        description: User in the blog
        required:
        - id
        properties:
          id:
            type: integer
            description: en.users.fields.id.description
          name:
            type: string
            description: en.users.fields.name.description
      YAML
    end
  end

  test "renders a template with view assigns" do
    Dir.chdir("./test/fixtures") do
      schema = Jbuilder::Schema.render template: "articles/index", assigns: { articles: Article.all }, title: "Article", description: "Article in the blog"

      assert_equal({
        type: :object,
        title: "Article",
        description: "Article in the blog",
        required: [],
        properties: {
          "articles" => {
            "type" => :array,
            "items" => {
              "id" => {type: :integer},
              "title" => {type: :string}
            }
          }
        }
      }, schema)
    end
  end

  test "renders a schema from a fixture" do
    schema = @renderer.render @article, title: "Article", description: "Article in the blog"

    assert_equal({
      type: :object,
      title: "Article",
      description: "Article in the blog",
      required: ["id"],
      properties: {
        "id" => {type: :integer, description: "en.articles.fields.id.description"},
        "status" => {type: :string, description: "en.articles.fields.status.description", enum: ["pending", "published", "archived"]},
        "title" => {type: :string, description: "en.articles.fields.title.description"},
        "body" => {type: :string, description: "en.articles.fields.body.description", pattern: /\w+/},
        "created_at" => {type: :string, description: "en.articles.fields.created_at.description", format: "date-time"},
        "updated_at" => {type: :string, description: "en.articles.fields.updated_at.description", format: "date-time"}
      }
    }, schema)
  end

  test "renders a schema from a fixture to yaml" do
    assert_equal <<~YAML, @renderer.yaml(@article, title: "Article", description: "Article in the blog")
      ---
      type: object
      title: Article
      description: Article in the blog
      required:
      - id
      properties:
        id:
          type: integer
          description: en.articles.fields.id.description
        status:
          type: string
          enum:
          - pending
          - published
          - archived
          description: en.articles.fields.status.description
        title:
          type: string
          description: en.articles.fields.title.description
        body:
          type: string
          pattern: \"\\\\w+\"
          description: en.articles.fields.body.description
        created_at:
          type: string
          format: date-time
          description: en.articles.fields.created_at.description
        updated_at:
          type: string
          format: date-time
          description: en.articles.fields.updated_at.description
    YAML
  end

  test "renders a schema from a fixture to json" do
    schema = @renderer.json @article, title: "Article", description: "Article in the blog"

    assert_equal({
      type: "object",
      title: "Article",
      description: "Article in the blog",
      required: ["id"],
      properties: {
        id: {type: "integer", description: "en.articles.fields.id.description"},
        status: {type: "string", description: "en.articles.fields.status.description", enum: ["pending", "published", "archived"]},
        title: {type: "string", description: "en.articles.fields.title.description"},
        body: {type: "string", description: "en.articles.fields.body.description", pattern: "\\w+"},
        created_at: {type: "string", description: "en.articles.fields.created_at.description", format: "date-time"},
        updated_at: {type: "string", description: "en.articles.fields.updated_at.description", format: "date-time"}
      }
    }, JSON.parse(schema, symbolize_names: true))
  end
end
