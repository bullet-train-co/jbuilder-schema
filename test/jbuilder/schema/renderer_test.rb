# frozen_string_literal: true

require "test_helper"

class Jbuilder::Schema::RendererTest < ActiveSupport::TestCase
  setup do
    I18n.backend.store_translations "en", articles: {fields: {
      id: {description: "en.articles.fields.id.description"},
      status: {description: "en.articles.fields.status.description"},
      title: {description: "en.articles.fields.title.description"},
      body: {description: "en.articles.fields.body.description"},
      created_at: {description: "en.articles.fields.created_at.description"},
      updated_at: {description: "en.articles.fields.updated_at.description"}
    }}

    @user = User.first
    @article = @user.articles.first

    @renderer = Jbuilder::Schema.renderer("test/fixtures/api/v1", locals: {current_user: @user})
  end

  teardown { I18n.reload! }

  test "renderers with default renderer" do
    I18n.backend.store_translations "en", users: {
      title: "User title",
      description: "User in the blog",
      fields: {
        id: {description: "en.users.fields.id.description"},
        name: {description: "en.users.fields.name.description"}
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
            type:
            - string
            - 'null'
            description: en.users.fields.name.description
        example:
          id: 1
          name: Generic name 0
      YAML
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

    assert_equal({
      type: :object,
      title: "Article",
      description: "Article in the blog",
      required: ["id"],
      properties: {
        "id" => {type: :integer, description: "en.articles.fields.id.description"},
        "status" => {type: [:string, "null"], description: "en.articles.fields.status.description", enum: ["pending", "published", "archived"]},
        "title" => {type: [:string, "null"], description: "en.articles.fields.title.description"},
        "body" => {type: [:string, "null"], description: "en.articles.fields.body.description", pattern: /\w+/},
        "created_at" => {type: [:string, "null"], description: "en.articles.fields.created_at.description", format: "date-time"},
        "updated_at" => {type: [:string, "null"], description: "en.articles.fields.updated_at.description", format: "date-time"}
      },
      example: {
        "id" => 1,
        "status" => "pending",
        "title" => "Generic title 0",
        "body" => "Lorem ipsum… 0",
        "created_at" => "2023-01-01T12:00:00.000Z",
        "updated_at" => "2023-01-01T12:00:00.000Z"
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
          type:
          - string
          - 'null'
          enum:
          - pending
          - published
          - archived
          description: en.articles.fields.status.description
        title:
          type:
          - string
          - 'null'
          description: en.articles.fields.title.description
        body:
          type:
          - string
          - 'null'
          pattern: "\\\\w+"
          description: en.articles.fields.body.description
        created_at:
          type:
          - string
          - 'null'
          format: date-time
          description: en.articles.fields.created_at.description
        updated_at:
          type:
          - string
          - 'null'
          format: date-time
          description: en.articles.fields.updated_at.description
      example:
        id: 1
        status: pending
        title: Generic title 0
        body: Lorem ipsum… 0
        created_at: '2023-01-01T12:00:00.000Z'
        updated_at: '2023-01-01T12:00:00.000Z'
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
        status: { type: %w[string null], description: "en.articles.fields.status.description", enum: ["pending", "published", "archived"]},
        title: { type: %w[string null], description: "en.articles.fields.title.description"},
        body: { type: %w[string null], description: "en.articles.fields.body.description", pattern: "\\w+"},
        created_at: { type: %w[string null], description: "en.articles.fields.created_at.description", format: "date-time"},
        updated_at: { type: %w[string null], description: "en.articles.fields.updated_at.description", format: "date-time"}
      },
      example: {
        id: 1,
        status: "pending",
        title: "Generic title 0",
        body: "Lorem ipsum… 0",
        created_at: "2023-01-01T12:00:00.000Z",
        updated_at: "2023-01-01T12:00:00.000Z"
      }
    }, JSON.parse(schema, symbolize_names: true))
  end
end
