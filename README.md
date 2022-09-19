# JbuilderSchema

Generate JSON Schema from Jbuilder files

[![Tests](https://github.com/bullet-train-co/jbuilder-schema/actions/workflows/tests.yml/badge.svg)](https://github.com/bullet-train-co/jbuilder-schema/actions)
[![Standard](https://github.com/bullet-train-co/jbuilder-schema/actions/workflows/standard.yml/badge.svg)](https://github.com/bullet-train-co/jbuilder-schema/actions)

## Installation

In Gemfile put `gem "jbuilder-schema"` **before** `gem "jbuilder"`:

    gem "jbuilder-schema", require: "jbuilder/schema"
    gem "jbuilder"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jbuilder-schema

## Usage

Wherever you want to generate schemas, you should extend `JbuilderSchema`:

    extend JbuilderSchema

Then you can use `jbuilder_schema` helper:

    jbuilder_schema('api/v1/articles/_article',
                    format: :yaml,
                    paths: view_paths.map(&:path),
                    model: Article,
                    title: 'Article',
                    description: 'Article in the blog',
                    locals: {
                      article: @article,
                      current_user: @user
                    })

`jbuilder_schema` helper takes `path` to Jbuilder template as a first argument and several optional arguments:

- `format`: Desired output format, can be either `:yaml` or `:json`. If no `format` option is passed, the output will be the Ruby Hash object;
- `paths`: If you need to scope any other paths than `app/views`, pass them as an array here;
- `model`: Model described in template, this is needed to populate `required` field in schema;
- `title` and `description`: Title and description of schema, if not passed then they will be grabbed from locale files (see *Titles & Descriptions*);
- `locals`: Here you should pass all the locals which are met in the jbuilder template. Those could be any objects as long as they respond to methods called on them in template.

Notice that partial templates should be prepended with an underscore just like in the name of the file (i.e. `_article` but not `article` an when using Jbuilder).

### Output

JbuilderSchema automatically sets `description`, `type`, and `required` options in JSON-Schema.

For example, if we have `_articles.json.jbilder` file:

    json.extract! article, :id, :title, :body, :created_at

The output for it will be:

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

### Customization

Sometimes you would want to set you own data in generated JSON-Schema. All you need to do is just pass hash with it under `schema` keyword in your jbuilder template:

    json.id article.id, schema: { type: :number }
    json.title article.title, schema: { minLength: 5, maxLength: 20 }
    json.body article.body, schema: { type: :text, maxLength: 500 }
    json.created_at article.created_at.strftime('%d/%m/%Y'), schema: { format: :date, pattern: "^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$" }

This will produce the following:

    ...
      properties:
        id:
          description: ID of an article
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
          pattern: ^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$

### Nested objects

### Collections

If an object or an array of objects is generated in template, either in root or in some field through Jbuilder partials, JSON-Schema `$ref` is generated pointing to object with the same name as partial. By default those schemas should appear in `"#/components/schemas/"`.

For example, if we have:

    json.user do
      json.partial! 'api/v1/users/user', user: user
    end

    json.articles do
      json.array! user.articles, partial: "api/v1/articles/article", as: :article
    end

The result would be:

    user:
      description: Information about user
      type: object
      $ref: #/components/schemas/user
    articles:
      type: array
      items:
        $ref: #/components/schemas/article
    
The path to component schemas can be configured with `components_path` variable, which defaults to `components/schemas`. See *Configuration* for more info.

### Titles & Descriptions

Descriptions for the fields are supposed to be found in locale files under `<underscored_plural_model_name>.fields.<field_name>.<description_name>`, for example:

    en:
      articles:
        fields:
          title:
            description: The title of an article

`<description_name>` can be configured (see *Configuration*), it defaults to `description`.

### Configuration

You can configure some variables that JbuilderSchema uses (for example, in `config/initializers/jbuilder_schema.rb`):

    JbuilderSchema.configure do |config|
        config.components_path = "components/schemas"   # could be "definitions/schemas"
        config.title_name = "title"                     # could be "label"
        config.description_name = "description"         # could be "heading"
    end

### RSwag

It's super easy to use JbuilderSchema with RSwag: just add `jbuilder_schema` helper in `swagger_helper.rb` like this:

    RSpec.configure do |config|
      extend JbuilderSchema

      ...

      config.swagger_docs = {

        ...
      
        components: {
          schemas: {
            article: jbuilder_schema('api/v1/articles/_article',
                                     format: :yaml,
                                     model: Article,
                                     title: 'Article',
                                     description: 'Article in the blog',
                                     locals: {
                                       article: FactoryBot.build(:article, id: 1),
                                       current_user: FactoryBot.build(:user, admin: true)
                                     })
          }
        }

        ...

      }

      ...

[//]: # (## Development)

[//]: # ()
[//]: # (After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.)

[//]: # ()
[//]: # (To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org]&#40;https://rubygems.org&#41;.)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bullet-train-co/jbuilder-schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
