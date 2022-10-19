# frozen_string_literal: true

require "test_helper"

class JbuilderSchema::BuilderTest < ActiveSupport::TestCase
  include JbuilderSchema

  test "renders a schema from a fixture to yaml" do
    user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    article = Article.new(id: 1, user: user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    schema = jbuilder_schema "api/v1/articles/_article",
      title: "Article",
      description: "Article in the blog",
      format: :yaml,
      paths: ["test/fixtures"],
      model: Article,
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
          type: integer
        title:
          type: string
        body:
          type: string
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time
    YAML
  end

  test "renders a schema from a fixture to json" do
    user = User.new(id: 1, email: "someone@example.org", name: "Someone")
    article = Article.new(id: 1, user: user, title: "New Things", body: "…are happening", created_at: DateTime.now, updated_at: DateTime.now)

    schema = jbuilder_schema "api/v1/articles/_article",
      title: "Article",
      description: "Article in the blog",
      format: :json,
      paths: ["test/fixtures"],
      model: Article,
      locals: { article: article, current_user: user }

    assert_equal({
      type: "object",
      title: "Article",
      description: "Article in the blog",
      required: ["id"],
      properties: {
        id: {type: "integer"},
        title: {type: "string"},
        body: {type: "string"},
        created_at: {type: "string", format: "date-time"},
        updated_at: {type: "string", format: "date-time"}
      }
    }, JSON.parse(schema, symbolize_names: true))
  end
end
