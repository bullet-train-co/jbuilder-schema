# Jbuilder::Schema

Generate JSON Schema compatible with OpenAPI 3 specs from Jbuilder files

[![Tests](https://github.com/bullet-train-co/jbuilder-schema/actions/workflows/tests.yml/badge.svg)](https://github.com/bullet-train-co/jbuilder-schema/actions)
[![Standard](https://github.com/bullet-train-co/jbuilder-schema/actions/workflows/standard.yml/badge.svg)](https://github.com/bullet-train-co/jbuilder-schema/actions)

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
Jbuilder::Schema.yaml('api/v1/articles/_article',
  title: 'Article',
  description: 'Article in the blog',
  paths: view_paths.map(&:path),
  model: Article,
  locals: {
    article: @article,
    current_user: @user
  })
```

`Jbuilder::Schema.yaml`/`json` takes the `path` to your Jbuilder template and several optional arguments:

- `title` and `description`: Title and description of schema, if not passed then they will be grabbed from locale files (see *[Titles & Descriptions](#titles--descriptions)*);
- `paths`: If you need to scope any other paths than `app/views`, pass them as an array here;
- `model`: Model described in template, this is needed to populate `required` field in schema;
- `locals`: pass the locals needed in the Jbuilder template. Those could be any objects as long as they respond to methods called on them in template.

Notice that partial templates should be prepended with an underscore just like in the name of the file (i.e. `_article` but not `article` when using Jbuilder).

### Output

Jbuilder::Schema automatically sets `description`, `type`, and `required` options in JSON-Schema.

For example, if we have `_articles.json.jbuilder` file:

```ruby
json.extract! article, :id, :title, :body, :created_at
```

Will output:

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

Sometimes you would want to set you own data in generated JSON-Schema. All you need to do is just pass hash with it under `schema` keyword in your Jbuilder template:

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

It's super easy to use Jbuilder::Schema with RSwag: just add `jbuilder_schema` helper in `swagger_helper.rb` like this:

```ruby
RSpec.configure do |config|
  config.swagger_docs = {
    components: {
      schemas: {
        article: Jbuilder::Schema.yaml('api/v1/articles/_article',
          model: Article,
          title: 'Article',
          description: 'Article in the blog',
          locals: {
            article: FactoryBot.build(:article, id: 1),
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
