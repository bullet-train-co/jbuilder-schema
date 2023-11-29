# frozen_string_literal: true

require "test_helper"
require "jbuilder/schema/template"

# Extracted partials tests from TemplateTest as there are quite a lot of them
class Jbuilder::Schema::PartialsTest < ActionView::TestCase
  # Assign the correct view path for the controller that ActionView::TestCase uses.
  TestController.prepend_view_path "test/fixtures/app/views/"

  setup do
    I18n.stubs(:t).returns("test")
    @user_schema = YAML.load_file(file_fixture("schemas/user.yaml"))
  end

  test "one-line object block with partial" do
    partial = json_for(User) do |json|
      json.user do
        json.partial! "users/user", user: User.first
      end
    end
    partial_with_extra_lines = json_for(User) do |json|
      json.user do
        # These are the
        # extra lines
        json.partial! "users/user", user: User.first

        # to test
      end
    end
    partial_with_inline_block = json_for(User) do |json|
      json.user { json.partial! "users/user", user: User.first }
    end
    result = {"user" => {type: :object, allOf: [{"$ref": "#/components/schemas/user"}], description: "test"}}

    assert_equal(result, partial)
    assert_equal(result, partial_with_extra_lines)
    assert_equal(result, partial_with_inline_block)
  end

  test "one-line array with partial" do
    partial = json_for(Article) do |json|
      json.partial! "articles/article", collection: Article.all, as: :article
    end
    partial_with_extra_lines = json_for(Article) do |json|
      # These are the
      # extra lines
      json.partial! "articles/article", collection: Article.all, as: :article

      # to test
    end
    result = {type: :array, items: {"$ref": "#/components/schemas/article"}}

    assert_equal(result, partial)
    assert_equal(result, partial_with_extra_lines)
  end

  test "one-line array block with partial" do
    partial = json_for(Article) do |json|
      json.articles User.first.articles do |article|
        json.partial! "articles/article", article: article
      end
    end
    partial_with_collection = json_for(Article) do |json|
      json.articles do
        json.partial! "articles/article", collection: Article.all, as: :article
      end
    end
    partial_with_extra_lines = json_for(Article) do |json|
      json.articles do
        # These are the
        # extra lines
        json.partial! "articles/article", collection: Article.all, as: :article

        # to test
      end
    end
    partial_with_inline_block = json_for(User) do |json|
      json.articles { json.partial! "articles/article", collection: Article.all, as: :article }
    end
    result = {"articles" => {type: :array, items: {"$ref": "#/components/schemas/article"}, description: "test"}}

    assert_equal(result, partial)
    assert_equal(result, partial_with_collection)
    assert_equal(result, partial_with_extra_lines)
    assert_equal(result, partial_with_inline_block)
  end

  test "collection partial inline" do
    result = json_for(User) do |json|
      json.users User.all, partial: "api/v1/users/user", as: :user
    end

    assert_equal({"users" => {type: :array, items: {"$ref": "#/components/schemas/user"}, description: "test"}}, result)
  end

  test "object partial inline" do
    result = json_for(Article) do |json|
      json.author Article.first.user, partial: "api/v1/users/user", as: :user
    end

    assert_equal({"author" => {type: :object, allOf: [{"$ref": "#/components/schemas/user"}], description: "test"}}, result)
  end

  test "block with array with partial" do
    result = json_for(Article) do |json|
      json.articles schema: {object: Article.first} do
        json.array! Article.all, partial: "api/v1/articles/article", as: :article
      end
    end

    assert_equal({"articles" => {type: :array, items: {"$ref": "#/components/schemas/article"}, description: "test"}}, result)
  end

  test "one-line text is defined correctly" do
    json = Jbuilder::Schema::Template.new nil
    def json._one_line?(...) = super

    one_line = <<-JBUILDER
      json.articles do
        json.partial! 'api/v1/articles/article', article: user.article
      end
    JBUILDER
    one_line_inline = <<-JBUILDER
      json.articles { json.partial! 'api/v1/articles/article', article: user.article }
    JBUILDER
    one_line_with_extra_lines = <<-JBUILDER
      json.articles do

        # ^ Empty line
                        
        # This is comment
            # This is comment with spaces
        json.partial! 'api/v1/articles/article', article: user.article
                                          
        # ^ Line with spaces
      end
    JBUILDER
    one_line_with_extra_lines_inline = <<-JBUILDER
      json.articles { ;   ;#comment;    #another comment; json.partial! 'api/v1/articles/article', article: user.article }
    JBUILDER
    many_lines = <<~JBUILDER
      json.articles do
        json.partial! 'api/v1/articles/article', article: user.article
        json.comments_count user.article.comments.count
      end
    JBUILDER
    many_lines_inline = <<~JBUILDER
      json.articles { json.partial! 'api/v1/articles/article', article: user.article; json.comments_count user.article.comments.count }
    JBUILDER

    assert_equal true, json._one_line?(one_line)
    assert_equal true, json._one_line?(one_line_inline)
    assert_equal true, json._one_line?(one_line_with_extra_lines)
    assert_equal true, json._one_line?(one_line_with_extra_lines_inline)
    assert_equal false, json._one_line?(many_lines)
    assert_equal false, json._one_line?(many_lines_inline)
  end

  private

  def json_for(model, **options, &block)
    Jbuilder::Schema::Template.new(view, object: model.new, **options, &block).attributes!
  end

  def json(&block)
    Jbuilder::Schema::Template.new(view, object: Article.new, &block)
  end
end
