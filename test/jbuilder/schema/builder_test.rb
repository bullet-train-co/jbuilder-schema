# frozen_string_literal: true

require "test_helper"

class JbuilderSchema::BuilderTest < ActiveSupport::TestCase
  include JbuilderSchema

  setup do
    I18n.backend.store_translations "en", articles: { fields: {
      id: { description: "en.articles.fields.id.description" },
      title: { description: "en.articles.fields.title.description" },
      body: { description: "en.articles.fields.body.description" },
      created_at: { description: "en.articles.fields.created_at.description" },
      updated_at: { description: "en.articles.fields.updated_at.description" },
    } }
  end

  teardown { I18n.reload! }

  test "renders a schema from a fixture" do
    user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    article = Article.new(id: 1, user: user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    schema = jbuilder_schema "api/v1/articles/_article",
      title: "Article",
      model: Article,
      description: "Article in the blog",
      paths: ["test/fixtures"],
      locals: { article: article, current_user: user }

    assert_equal({
      type: :object,
      title: "Article",
      description: "Article in the blog",
      required: [:id],
      properties: {
        id: {type: :integer, description: "en.articles.fields.id.description"},
        title: {type: :string, description: "en.articles.fields.title.description"},
        body: {type: :string, description: "en.articles.fields.body.description", pattern: /\w+/},
        created_at: {type: :string, description: "en.articles.fields.created_at.description", format: "date-time"},
        updated_at: {type: :string, description: "en.articles.fields.updated_at.description", format: "date-time"},
      }
    }, schema)
  end

  test "renders a schema from a fixture to yaml" do
    user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    article = Article.new(id: 1, user: user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    schema = jbuilder_schema "api/v1/articles/_article",
      title: "Article",
      model: Article,
      description: "Article in the blog",
      format: :yaml,
      paths: ["test/fixtures"],
      locals: { article: article, current_user: user }

    assert_equal <<~YAML, schema
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
    user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    article = Article.new(id: 1, user: user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    schema = jbuilder_schema "api/v1/articles/_article",
      title: "Article",
      model: Article,
      description: "Article in the blog",
      format: :json,
      paths: ["test/fixtures"],
      locals: { article: article, current_user: user }

    assert_equal({
      type: "object",
      title: "Article",
      description: "Article in the blog",
      required: ["id"],
      properties: {
        id: {type: "integer", description: "en.articles.fields.id.description"},
        title: {type: "string", description: "en.articles.fields.title.description"},
        body: {type: "string", description: "en.articles.fields.body.description", pattern: "\\w+"},
        created_at: {type: "string", description: "en.articles.fields.created_at.description", format: "date-time"},
        updated_at: {type: "string", description: "en.articles.fields.updated_at.description", format: "date-time"},
      }
    }, JSON.parse(schema, symbolize_names: true))
  end
end
