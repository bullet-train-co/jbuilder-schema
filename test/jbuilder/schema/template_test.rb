# frozen_string_literal: true

require "test_helper"
require "jbuilder/schema/template"

class Jbuilder::Schema::TemplateTest < ActionView::TestCase
  # Assign the correct view path for the controller that ActionView::TestCase uses.
  TestController.prepend_view_path "test/fixtures/app/views/"

  setup do
    I18n.stubs(:t).returns("test")
    @user_schema = YAML.load_file(file_fixture("schemas/user.yaml"))
  end

  test "user fields" do
    assert_equal({description: "test", type: :integer}, json.integer(1))
    assert_equal({description: "test", type: :number}, json.number(1.5))
    assert_equal({description: "test", type: :number}, json.big_decimal(BigDecimal("1.5", 1)))
    assert_equal({description: "test", type: :string}, json.string("String"))
    assert_equal({description: "test", type: :string}, json.nil_method(nil))
    assert_equal({description: "test", type: :string, format: "date"}, json.time(Date.new(2012, 12, 0o1)))
    assert_equal({description: "test", type: :string, format: "time"}, json.time(Time.now))
    assert_equal({description: "test", type: :string, format: "date-time"}, json.time(DateTime.new(2012, 12, 0o1)))
    assert_equal({description: "test", type: :string, format: "date-time"}, json.time_with_zone(ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample)))
    assert_equal({description: "test", type: :boolean}, json.true_method(true))
    assert_equal({description: "test", type: :boolean}, json.false_method(false))
    assert_equal({description: "test", type: :array, contains: {type: :string}, minContains: 0}.as_json, json.string_array(%w[a b c d]).as_json)
    assert_equal({description: "test", type: :array, contains: {anyOf: [{type: :string}, {type: :integer}, {type: :number}, {type: :boolean}]}, minContains: 0}.as_json, json.multitype_array(["a", 1, 1.5, false]).as_json)
  end

  test "user fields with schema types" do
    assert_equal({description: "test", type: :string}, json.integer(1, schema: {type: :string}))
    assert_equal({description: "test", type: :string}, json.number(1.5, schema: {type: :string}))
    assert_equal({description: "test", type: :string}, json.big_decimal(BigDecimal("1.5", 1), schema: {type: :string}))
    assert_equal({description: "test", type: :integer}, json.string("String", schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.nil_method(nil, schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.time(Date.new(2012, 12, 0o1), schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.time(Time.now, schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.time(DateTime.new(2012, 12, 0o1), schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.time_with_zone(ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample), schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.true_method(true, schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}, json.false_method(false, schema: {type: :integer}))
    assert_equal({description: "test", type: :integer}.as_json, json.string_array(%w[a b c d], schema: {type: :integer}).as_json)
    assert_equal({description: "test", type: :integer}.as_json, json.multitype_array(["a", 1, 1.5, false], schema: {type: :integer}).as_json)
  end

  test "json.extract!" do
    result = json_for(Article) do |json|
      json.extract!(Article.first, :id, :title, :body)
    end

    assert_equal({"id" => {description: "test", type: :integer}, "title" => {description: "test", type: :string}, "body" => {description: "test", type: :string}}, result)
  end

  test "json.extract! with schema arguments" do
    result = json_for(Article) do |json|
      json.extract!(Article.first, :id, :title, :body, schema: {id: {type: :string}, body: {type: :text}})
    end

    assert_equal({"id" => {description: "test", type: :string}, "title" => {description: "test", type: :string}, "body" => {description: "test", type: :text}}, result)
  end

  test "json.extract! with hash" do
    result = json_for(Hash) do |json|
      json.extract!({id: 1, title: "sup", body: "somebody once told me the world…"}, :id, :title, :body)
    end

    assert_equal({"id" => {description: "test", type: :integer}, "title" => {description: "test", type: :string}, "body" => {description: "test", type: :string}}, result)
  end

  test "json.extract! with hash and schema arguments" do
    result = json_for(Hash) do |json|
      json.extract!({id: 1, title: "sup", body: "somebody once told me the world…"}, :id, :title, :body, schema: {id: {type: :string}, body: {type: :text}})
    end

    assert_equal({"id" => {description: "test", type: :string}, "title" => {description: "test", type: :string}, "body" => {description: "test", type: :text}}, result)
  end

  test "object without schema attributes" do
    # TODO: This also should probably include :name as required
    # https://github.com/bullet-train-co/jbuilder-schema/issues/65
    result = json_for(Article) do |json|
      json.user User.first, :id, :name, :created_at
    end

    assert_equal({"user" => {type: :object, title: "test", description: "test", required: %w[id], properties: {"id" => {type: :integer, description: "test"}, "name" => {type: [:string, "null"], description: "test"}, "created_at" => {type: [:string, "null"], format: "date-time", description: "test"}}}}, result)
  end

  test "object with schema attributes" do
    result = json_for(Article) do |json|
      json.user User.first, :id, :name, :created_at, schema: {object: User.first, object_title: "User", object_description: "User writes articles"}
    end

    assert_equal({"user" => {type: :object, title: "User", description: "User writes articles", required: %w[id name], properties: {"id" => {type: :integer, description: "test"}, "name" => {type: :string, description: "test"}, "created_at" => {type: [:string, "null"], format: "date-time", description: "test"}}}}, result)
  end

  test "simple block" do
    result = json_for(User) do |json|
      json.author { json.id 123 }
    end

    assert_equal({"author" => {type: :object, title: "test", description: "test", required: ["id"], properties: {"id" => {type: :integer, description: "test"}}}}, result)
  end

  test "block with schema object attribute" do
    result = json_for(User) do |json|
      json.author schema: {object: Article.first.user} do
        json.id 123
      end
    end

    assert_equal({"author" => {type: :object, title: "test", description: "test", required: ["id"], properties: {"id" => {description: "test", type: :integer}}}}, result)
  end

  test "block with array" do
    result = json_for(Article) do |json|
      json.articles { json.array! Article.all, :id, :title }
    end

    assert_equal({"articles" => {description: "test", type: :array, items: {type: :object, title: "test", description: "test", required: %w[id title], properties: {"id" => {description: "test", type: :integer}, "title" => {description: "test", type: :string}}}}}, result)
  end

  test "array with block" do
    result = json_for(Article) do |json|
      json.array! Article.all do |article|
        json.id article.id
        json.title article.title
        json.body article.body
      end
    end

    assert_equal({type: :array, items: {type: :object, title: "test", description: "test", required: %w[id title body], properties: {"id" => {description: "test", type: :integer}, "title" => {description: "test", type: :string}, "body" => {description: "test", type: :string}}}}, result)
  end

  test "array with block with schema attributes" do
    result = json_for(Article) do |json|
      json.array! Article.all do |article|
        json.id article.id, schema: {type: :string}
        json.title article.title
        json.body article.body, schema: {type: :text}
      end
    end

    assert_equal({type: :array, items: {type: :object, title: "test", description: "test", required: %w[id title body], properties: {"id" => {type: :string, description: "test"}, "title" => {type: :string, description: "test"}, "body" => {type: :text, description: "test"}}}}, result )
  end

  test "block with merge" do
    result = json_for(Article) do |json|
      json.author do
        json.id 123
        json.merge!({name: "David"})
      end
    end

    # TODO: should the merged name be a symbol or string here? E.g. should it pass through `_key`?
    assert_equal({"author" => {type: :object, title: "test", description: "test", required: ["id"], properties: {"id" => {type: :integer, description: "test"}, :name => {type: [:string, "null"], description: "test"}}}}, result)
  end

  test "collections" do
    assert_equal({description: "test", type: :array, items: {type: :object, title: "test", description: "test", required: %w[id title], properties: {"id" => {description: "test", type: :integer}, "title" => {description: "test", type: :string}}}}, json.articles(Article.all, :id, :title))
    assert_equal({type: :array, items: {
      type: :object, title: "test", description: "test", required: %w[id user_id status title body], properties: {
        "id" => {description: "test", type: :integer},
        "public_id" => {description: "test", type: [:string, "null"]},
        "status" => {description: "test", type: :string, enum: %w[pending published archived]},
        "title" => {description: "test", type: :string},
        "body" => {description: "test", type: :string},
        "created_at" => {description: "test", type: [:string, "null"], format: "date-time"},
        "updated_at" => {description: "test", type: [:string, "null"], format: "date-time"},
        "user_id" => {description: "test", type: :integer}
    }}, description: "test"}, json.articles(Article.all))
  end

  test "empty collections" do
    result = json_for(User) do |json|
      json.articles []
    end

    assert_equal({"articles" => {type: :array, items: {"$ref": "#/components/schemas/article"}, description: "test"}}, result)
  end

  test "pass through of internal instance variables" do
    result = json_for(User) do |json|
      # Test our internal options don't bar someone from adding them to their JSON.
      json.type :array
      json.items [1]
      json.properties "hm"
      json.attributes "ya"
      json.configuration "guess what"
    end

    assert_equal({
      "type" => {type: :string, description: "test"},
      "items" => {type: :array, minContains: 0, contains: {type: :integer}, description: "test"},
      "properties" => {type: :string, description: "test"},
      "attributes" => {type: :string, description: "test"},
      "configuration" => {type: :string, description: "test"}
    }, result)
  end

  test "key format" do
    result = json_for(User) do |json|
      json.key_format! camelize: :upper
      json.id 123
      json.name "David"
    end

    assert_equal({"Id" => {description: "test", type: :integer}, "Name" => {description: "test", type: :string}}, result)
  end

  test "deep key format" do
    result = json_for(Article) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.title "Article"
      json.author {
        json.id 123
        json.name "David"
      }
    end

    assert_equal({"Id" => {description: "test", type: :integer}, "Title" => {description: "test", type: :string}, "Author" => {type: :object, title: "test", description: "test", required: ["Id"], properties: {"Id" => {type: :integer, description: "test"}, "Name" => {type: [:string, "null"], description: "test"}}}}, result)
  end

  test "deep key format with array" do
    result = json_for(Article) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.name "David"
      json.articles Article.all, :title, :created_at
    end

    assert_equal({"Id" => {description: "test", type: :integer}, "Name" => {description: "test", type: :string}, "Articles" => {description: "test", type: :array, items: {type: :object, title: "test", description: "test", required: %w[Title], properties: {"Title" => {description: "test", type: :string}, "CreatedAt" => {description: "test", type: [:string, "null"], format: "date-time"}}}}}, result)
  end

  test "schematize type" do
    json = Jbuilder::Schema::Template.new nil
    def json._schema(...) = super # We're marking it public on the singleton, but can't use `public` since we're ultimately a BasicObject.

    assert_equal({type: :integer}, json._schema(nil, 1))
    assert_equal({type: :number}, json._schema(nil, 1.5))
    assert_equal({type: :number}, json._schema(nil, BigDecimal("1.5", 1)))
    assert_equal({type: :string}, json._schema(nil, "String"))
    assert_equal({type: :string}, json._schema(nil, nil))
    assert_equal({type: :string, format: "date"}, json._schema(nil, Date.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "time"}, json._schema(nil, Time.now))
    assert_equal({type: :string, format: "date-time"}, json._schema(nil, DateTime.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "date-time"}, json._schema(nil, ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample)))
    assert_equal({type: :boolean}, json._schema(nil, true))
    assert_equal({type: :boolean}, json._schema(nil, false))
    assert_equal({type: :array, minContains: 0, contains: {type: :string}}.as_json, json._schema(nil, %w[a b c d]).as_json)
    assert_equal({type: :array, minContains: 0, contains: {anyOf: [{type: :string}, {type: :integer}, {type: :number}, {type: :boolean}]}}.as_json, json._get_type(["a", 1, 1.5, false]).as_json)
    assert_equal({type: :array, minContains: 0, contains: {anyOf: [{type: :string}, {type: :integer}]}}.as_json, json._get_type(["a", 1, "b", 2]).as_json)
    assert_equal({type: :array, minContains: 0, contains: {anyOf: [{type: :string}, {type: :integer}, {type: :array, minContains: 0, contains: {anyOf: [{type: :integer}, {type: :string}, {type: :number}, {type: :object, properties: {o: {type: :integer}, p: {type: :string}}}]}}, {type: :object, properties: {a: {type: :integer}, b: {type: :string}}}, {type: :object, properties: {c: {type: :integer}, d: {type: :object, properties: {z: {type: :integer}, x: {type: :string}}}}}]}}.as_json, json._get_type(["a", 1, [1, 2, "a"], {a: 1, b: "b"}, [3, 4.55, {o: 5, p: "p"}], {c: 2, d: {z: 3, x: "b"}}]).as_json)
  end

  test "schema! with array" do
    json = json { _1.array! Article.all, :title }
    assert_equal({type: :array, items: {type: :object, title: "test", description: "test", required: ["title"], properties: {"title" => {type: :string, description: "test"}}}}, json.schema!)
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
