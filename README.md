# Jbuilder::Schema

Generate JSON Schema compatible with OpenAPI 3 specs from Jbuilder files

## Installation

In your Gemfile, put `gem "jbuilder-schema"` after Jbuilder:

    gem "jbuilder"
    gem "jbuilder-schema"

And run:

    $ bundle

Or install it yourself as:

    $ gem install jbuilder-schema

## Usage

Wherever you want to generate schemas, call `Jbuilder::Schema.yaml` or `Jbuilder::Schema.json`:

```ruby
Jbuilder::Schema.yaml(@article, title: 'Article', description: 'Article in the blog', locals: { current_user: @user })
```

Under the hood `Jbuilder::Schema.yaml`/`json` will use Action View's `render` method and support the same arguments.

So in the above example, the `@article`'s `to_partial_path` path is used to find and render a `articles/_article.json.jbuilder` template, and `article` is available in the partial.

Additionally, we can pass any needed `locals:`.

The `title` and `description` set the title and description of the schema — though they can also come from locale files (see *[Titles & Descriptions](#titles--descriptions)*);

### Use with a directory within app/views

If you have a directory within app/views where your Jbuilder templates are, you can use `renderer` to capture that along with any `locals:` common to the templates you'll render:

```ruby
jbuilder = Jbuilder::Schema.renderer('app/views/api/v1', locals: { current_user: @user })
jbuilder.yaml @article, title: 'Article', description: 'Article in the blog'
```

This means you don't have to write out the partial path, which gets tedious with multiple schema renders:

```ruby
Jbuilder::Schema.yaml(partial: 'api/v1/articles/article', locals: { article: @article, current_user: @user }, title: 'Article', description: 'Article in the blog')
```

### Rendering a template

If you're rendering a template like `app/views/articles/index.jbuilder`:

```ruby
json.articles @articles, :id, :title
```

You'll need to pass the relative template path in `template:` and any needed instance variables in `assigns:` like so:

```ruby
Jbuilder::Schema.yaml(template: "articles/index", assigns: { articles: Article.first(3) })
```

### Output

Jbuilder::Schema automatically sets `description`, `type`, and `required` options in JSON-Schema.

For example, if we have a `_article.json.jbuilder` file:

```ruby
json.extract! article, :id, :title, :body, :created_at
```

This will produce the following:

```yaml
type: object
title: Article
description: Article in the blog
required:
  - id
  - title
  - body
properties:
  id:
    description: ID of an article
    type: integer
  title:
    description: Title of an article
    type: string
  body:
    description: Contents of an article
    type: string
  created_at:
    description: Timestamp when article was created
    type: string
    format: date-time
```

### Customization

#### Simple

To set your own data in the generated JSON-Schema pass a `schema:` hash:

```ruby
json.id article.id, schema: { type: :number, description: "Custom ID description" }
json.title article.title, schema: { minLength: 5, maxLength: 20 }
json.body article.body, schema: { type: :text, maxLength: 500 }
json.created_at article.created_at.strftime('%d/%m/%Y'), schema: { format: :date, pattern: /^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$/ }
```

This will produce the following:

```yaml
...
  properties:
    id:
      description: Custom ID description
      type: number
    title:
      description: Title of an article
      type: string
      minLength: 5
      maxLength: 20
    body:
      description: Contents of an article
      type: string
      maxLength: 500
    created_at:
      description: Timestamp when article was created
      type: string
      format: date
      pattern: "^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$"
```

#### Bulk

You can customize output for multiple fields at once:

```ruby
json.extract! user, :id, :name, :email, schema: {id: {type: :string}, email: {type: :email, pattern: /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/}}
```

### Nested objects

When you have nested objects in your Jbuilder template, you have to pass it to `schema: {object: <nested_object>}` when the block starts:

```ruby
json.extract! article
json.author schema: {object: article.user, object_title: "Author", object_description: "Authors are users who write articles"} do
  json.extract! article.user
end
```

This will help Jbuilder::Schema to process those fields right.

### Collections

If an object or an array of objects is generated in template, either in root or in some field through Jbuilder partials, JSON-Schema `$ref` is generated pointing to object with the same name as partial. By default those schemas should appear in `"#/components/schemas/"`.

For example, if we have:

```ruby
json.user do
  json.partial! 'api/v1/users/user', user: user
end

json.articles do
  json.array! user.articles, partial: "api/v1/articles/article", as: :article
end
```

The result would be:

```yaml
user:
  type: object
  $ref: #/components/schemas/user
articles:
  type: array
  items:
    $ref: #/components/schemas/article
```

The path to component schemas can be configured with `components_path` variable, which defaults to `components/schemas`. See *[Configuration](#configuration)* for more info.

### Titles & Descriptions

Custom titles and descriptions for objects can be specified when calling `jbuilder-schema` helper (see *[Usage](#usage)*), for fields and nested objects within `schema` attributes (see *[Customization](#simple)* and *[Nested objects](#nested-objects)*). If not set, they will be searched in locale files.

Titles and descriptions for the models are supposed to be found in locale files under `<underscored_plural_model_name>.<title_name>` and `<underscored_plural_model_name>.<description_name>`, for example:

```yaml
en:
  articles:
    title: Article
    description: The main object on the blog
```

Descriptions for the fields are supposed to be found in locale files under `<underscored_plural_model_name>.fields.<field_name>.<description_name>`, for example:

```yaml
en:
  articles:
    fields:
      title:
        description: The title of an article
```

`<title_name>` and `<description_name>` can be configured (see *[Configuration](#configuration)*), it defaults to `title` and `description`.

### Configuration

You can configure some variables that Jbuilder::Schema uses (for example, in `config/initializers/jbuilder_schema.rb`):

```ruby
Jbuilder::Schema.configure do |config|
  config.components_path = "components/schemas"   # could be "definitions/schemas"
  config.title_name = "title"                     # could be "label"
  config.description_name = "description"         # could be "heading"
end
```

### RSwag

You can use the `yaml`/`json` methods in your `swagger_helper.rb` like this:

```ruby
RSpec.configure do |config|
  config.swagger_docs = {
    components: {
      schemas: {
        article: Jbuilder::Schema.yaml(FactoryBot.build(:article, id: 1),
          title: 'Article',
          description: 'Article in the blog',
          locals: {
            current_user: FactoryBot.build(:user, admin: true)
          })
      }
    }
  }
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bullet-train-co/jbuilder-schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
