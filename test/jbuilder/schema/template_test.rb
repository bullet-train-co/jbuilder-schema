# frozen_string_literal: true

require "test_helper"
require "jbuilder/schema/template"
require "jbuilder/schema/handler"

class TemplateTest < ActiveSupport::TestCase
  test "user fields" do
    assert_equal({type: :integer}, json.integer(1))
    assert_equal({type: :number}, json.number(1.5))
    assert_equal({type: :number}, json.big_decimal(BigDecimal("1.5", 1)))
    assert_equal({type: :string}, json.string("String"))
    assert_equal({type: :string}, json.nil_method(nil))
    assert_equal({type: :string, format: "date-time"}, json.time(DateTime.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "date-time"}, json.time_with_zone(ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample)))
    assert_equal({type: :boolean}, json.true_method(true))
    assert_equal({type: :boolean}, json.false_method(false))
    assert_equal({type: :array, contains: {type: :string}, minContains: 0}.as_json, json.string_array(%w[a b c d]).as_json)
    assert_equal({type: :array, contains: {type: %i[string integer number boolean]}, minContains: 0}.as_json, json.multitype_array(["a", 1, 1.5, false]).as_json)
  end

  test "json.extract!" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.extract!(articles.first, :id, :title, :body)
    end

    assert_equal({id: {type: :integer}, title: {type: :string}, body: {type: :string}}, result.attributes)
  end

  test "simple block" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.author { json.id 123 }
    end

    assert_equal({author: {type: :object, properties: {id: {type: :integer}}}}, result.attributes)
  end

  test "block with array" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.articles { json.array! FactoryBot.create_list(:article, 3), :id, :title }
    end

    assert_equal({articles: {type: :array, items: {id: {type: :integer}, title: {type: :string}}}}, result.attributes)
  end

  test "block with merge" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.author {
        json.id 123
        json.merge!({name: "David"})
      }
    end

    assert_equal({author: {type: :object, properties: {id: {type: :integer}, name: {type: :string}}}}, result.attributes)
  end

  test "block with partial" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.user { json.partial! "api/v1/users/user", user: FactoryBot.create(:user) }
    end

    assert_equal({user: {:type => :object, :$ref => "#/components/schemas/user"}}, result.attributes)
  end

  test "block with array with partial" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.articles { json.array! articles, partial: "api/v1/articles/article", as: :article }
    end

    assert_equal({articles: {type: :array, items: {:$ref => "#/components/schemas/article"}}}, result.attributes)
  end

  test "collections" do
    assert_equal({type: :array, items: {id: {type: :integer}, title: {type: :string}}}, json.articles(articles, :id, :title))
    assert_equal({type: :array, items: {id: {type: :integer},
                                        title: {type: :string},
                                        body: {type: :string},
                                        created_at: {type: :string, format: "date-time"},
                                        updated_at: {type: :string, format: "date-time"},
                                        user_id: {type: :integer}}},
      json.articles(articles))
  end

  test "jbuilder methods" do
    assert_equal({type: :string}, json.set!(:name, "David"))
    assert_equal({:$ref => "#/components/schemas/article"}, json.partial!("articles/article", collection: articles, as: :article))
    assert_equal({id: {type: :integer}, title: {type: :string}}, json.array!(articles, :id, :title))
  end

  test "key format" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.key_format! camelize: :upper
      json.id 123
      json.name "David"
    end

    assert_equal({Id: {type: :integer}, Name: {type: :string}}, result.attributes)
  end

  test "deep key format" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.title "Article"
      json.author {
        json.id 123
        json.name "David"
      }
    end

    assert_equal({Id: {type: :integer}, Title: {type: :string}, Author: {type: :object, properties: {Id: {type: :integer}, Name: {type: :string}}}}, result.attributes)
  end

  test "deep key format with array" do
    result = JbuilderSchema::Template.new(JbuilderSchema::Handler) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.name "David"
      json.articles articles, :title, :created_at
    end

    assert_equal({Id: {type: :integer}, Name: {type: :string}, Articles: {type: :array, items: {Title: {type: :string}, CreatedAt: {type: :string, format: "date-time"}}}}, result.attributes)
  end

  test "schematize type" do
    assert_equal({type: :integer}, json.send(:_schema, 1))
    assert_equal({type: :number}, json.send(:_schema, 1.5))
    assert_equal({type: :number}, json.send(:_schema, BigDecimal("1.5", 1)))
    assert_equal({type: :string}, json.send(:_schema, "String"))
    assert_equal({type: :string}, json.send(:_schema, nil))
    assert_equal({type: :string, format: "date-time"}, json.send(:_schema, DateTime.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "date-time"}, json.send(:_schema, ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample)))
    assert_equal({type: :boolean}, json.send(:_schema, true))
    assert_equal({type: :boolean}, json.send(:_schema, false))
    assert_equal({type: :array, contains: {type: :string}, minContains: 0}.as_json, json.send(:_schema, %w[a b c d]).as_json)
    assert_equal({type: :array, contains: {type: %i[string integer number boolean]}, minContains: 0}.as_json, json.send(:_get_type, ["a", 1, 1.5, false]).as_json)
  end

  private

  def json
    JbuilderSchema::Template.new(JbuilderSchema::Handler)
  end

  def articles
    FactoryBot.create_list(:article, 3)
  end
end
