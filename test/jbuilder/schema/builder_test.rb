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
          description: en.articles.fields.id.description
          type: integer
        status:
          description: en.articles.fields.status.description
          type: string
          enum:
          - pending
          - published
          - archived
        title:
          description: en.articles.fields.title.description
          type: string
        body:
          description: en.articles.fields.body.description
          type: string
          pattern: \"\\\\w+\"
        created_at:
          description: en.articles.fields.created_at.description
          type: string
          format: date-time
        updated_at:
          description: en.articles.fields.updated_at.description
          type: string
          format: date-time
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
