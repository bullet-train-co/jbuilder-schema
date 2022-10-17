# frozen_string_literal: true

require "test_helper"
require "jbuilder/schema/template"

class TemplateTest < ActiveSupport::TestCase
  def setup
    super
    I18n.stubs(:t).returns("test")
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
    assert_equal({description: "test", type: :array, contains: {type: %i[string integer number boolean]}, minContains: 0}.as_json, json.multitype_array(["a", 1, 1.5, false]).as_json)
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
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.extract!(articles.first, :id, :title, :body)
    end

    assert_equal({id: {description: "test", type: :integer}, title: {description: "test", type: :string}, body: {description: "test", type: :string}}, result.attributes)
  end

  test "json.extract! with schema arguments" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.extract!(articles.first, :id, :title, :body, schema: {id: {type: :string}, body: {type: :text}})
    end

    assert_equal({id: {description: "test", type: :string}, title: {description: "test", type: :string}, body: {description: "test", type: :text}}, result.attributes)
  end

  test "simple block" do
    result = JbuilderSchema::Template.new(model: User) do |json|
      json.author { json.id 123 }
    end

    assert_equal({author: {type: :object, title: "test", description: "test", required: [:id], properties: {id: {description: "test", type: :integer}}}}, result.attributes)
  end

  test "block with schema object attribute" do
    result = JbuilderSchema::Template.new(model: User) do |json|
      json.author schema: {object: articles.first.user} do
        json.id 123
      end
    end

    assert_equal({author: {type: :object, title: "test", description: "test", required: [:id], properties: {id: {description: "test", type: :integer}}}}, result.attributes)
  end

  test "block with array" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.articles { json.array! FactoryBot.create_list(:article, 3), :id, :title }
    end

    assert_equal({articles: {description: "test", type: :array, items: {id: {description: "test", type: :integer}, title: {description: "test", type: :string}}}}, result.attributes)
  end

  test "array with block" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.array! articles do |article|
        json.id article.id
        json.title article.title
        json.body article.body
      end
    end

    assert_equal({items: {id: {description: "test", type: :integer}, title: {description: "test", type: :string}, body: {description: "test", type: :string}}}, result.attributes)
  end

  test "array with block with schema attributes" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.array! articles do |article|
        json.id article.id, schema: {type: :string}
        json.title article.title
        json.body article.body, schema: {type: :text}
      end
    end

    assert_equal({items: {id: {description: "test", type: :string}, title: {description: "test", type: :string}, body: {description: "test", type: :text}}}, result.attributes)
  end

  test "block with merge" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.author do
        json.id 123
        json.merge!({name: "David"})
      end
    end

    assert_equal({author: {type: :object, title: "test", description: "test", required: [:id], properties: {id: {description: "test", type: :integer}, name: {description: "test", type: :string}}}}, result.attributes)
  end

  test "block with partial" do
    result = JbuilderSchema::Template.new(model: User) do |json|
      json.user { json.partial! "api/v1/users/user", user: FactoryBot.create(:user) }
    end

    assert_equal({user: {:description => "test", :type => :object, :$ref => "#/components/schemas/user"}}, result.attributes)
  end

  test "block with array with partial" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.articles schema: {object: articles.first} do
        json.array! articles, partial: "api/v1/articles/article", as: :article
      end
    end

    assert_equal({articles: {description: "test", type: :array, items: {:$ref => "#/components/schemas/article"}}}, result.attributes)
  end

  test "collections" do
    assert_equal({description: "test", type: :array, items: {id: {description: "test", type: :integer}, title: {description: "test", type: :string}}}, json.articles(articles, :id, :title))
    assert_equal({
      description: "test", type: :array,
      items: {id: {description: "test", type: :integer},
      title: {description: "test", type: :string},
      body: {description: "test", type: :string},
      created_at: {description: "test", type: :string, format: "date-time"},
      updated_at: {description: "test", type: :string, format: "date-time"},
      user_id: {description: "test", type: :integer}}
    }, json.articles(articles))
  end

  test "jbuilder methods" do
    assert_equal({description: "test", type: :string}, json.set!(:name, "David"))
    assert_equal({:$ref => "#/components/schemas/article"}, json.partial!("articles/article", collection: articles, as: :article))
    assert_equal({id: {description: "test", type: :integer}, title: {description: "test", type: :string}}, json.array!(articles, :id, :title))
    assert_equal({id: {description: "test", type: :string}, title: {description: "test", type: :string}}, json.array!(articles, :id, :title, schema: {id: {type: :string}}))
  end

  test "key format" do
    result = JbuilderSchema::Template.new(model: User) do |json|
      json.key_format! camelize: :upper
      json.id 123
      json.name "David"
    end

    assert_equal({Id: {description: "test", type: :integer}, Name: {description: "test", type: :string}}, result.attributes)
  end

  test "deep key format" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.title "Article"
      json.author {
        json.id 123
        json.name "David"
      }
    end

    assert_equal({Id: {description: "test", type: :integer}, Title: {description: "test", type: :string}, Author: {type: :object, title: "test", description: "test", required: [:Id], properties: {Id: {description: "test", type: :integer}, Name: {description: "test", type: :string}}}}, result.attributes)
  end

  test "deep key format with array" do
    result = JbuilderSchema::Template.new(model: Article) do |json|
      json.key_format! camelize: :upper
      json.deep_format_keys!
      json.id 123
      json.name "David"
      json.articles articles, :title, :created_at
    end

    assert_equal({Id: {description: "test", type: :integer}, Name: {description: "test", type: :string}, Articles: {description: "test", type: :array, items: {Title: {description: "test", type: :string}, CreatedAt: {description: "test", type: :string, format: "date-time"}}}}, result.attributes)
  end

  test "schematize type" do
    json = JbuilderSchema::Template.new

    assert_equal({type: :integer}, json.send(:_schema, nil, 1))
    assert_equal({type: :number}, json.send(:_schema, nil, 1.5))
    assert_equal({type: :number}, json.send(:_schema, nil, BigDecimal("1.5", 1)))
    assert_equal({type: :string}, json.send(:_schema, nil, "String"))
    assert_equal({type: :string}, json.send(:_schema, nil, nil))
    assert_equal({type: :string, format: "date"}, json.send(:_schema, nil, Date.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "time"}, json.send(:_schema, nil, Time.now))
    assert_equal({type: :string, format: "date-time"}, json.send(:_schema, nil, DateTime.new(2012, 12, 0o1)))
    assert_equal({type: :string, format: "date-time"}, json.send(:_schema, nil, ActiveSupport::TimeWithZone.new(Time.now, ActiveSupport::TimeZone.all.sample)))
    assert_equal({type: :boolean}, json.send(:_schema, nil, true))
    assert_equal({type: :boolean}, json.send(:_schema, nil, false))
    assert_equal({type: :array, contains: {type: :string}, minContains: 0}.as_json, json.send(:_schema, nil, %w[a b c d]).as_json)
    assert_equal({type: :array, contains: {type: %i[string integer number boolean]}, minContains: 0}.as_json, json.send(:_get_type, ["a", 1, 1.5, false]).as_json)
  end

  private

  def json
    JbuilderSchema::Template.new(model: Article)
  end

  def articles
    FactoryBot.create_list(:article, 3)
  end
end
