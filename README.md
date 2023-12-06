# Jbuilder::Schema

Easily Generate JSON Schemas from Jbuilder Templates for OpenAPI 3.1

## Quick Start

### Installation

Add this to your Gemfile:

    gem "jbuilder"
    gem "jbuilder-schema"

Then, run `bundle` or install it manually using `gem install jbuilder-schema`.

### Generating Schemas

Use `Jbuilder::Schema.yaml` or `Jbuilder::Schema.json` to create schemas. For example:

```ruby
Jbuilder::Schema.yaml(@article, title: 'Article', description: 'Article in the blog', locals: { current_user: @user })
```

This will render a Jbuilder template (e.g., `articles/_article.json.jbuilder`) and make `@article` available in the partial. You can also pass additional locals.

### Advanced Usage

#### Rendering Specific Directories

If your Jbuilder templates are in a specific directory, use `Jbuilder::Schema.renderer`:

```ruby
jbuilder = Jbuilder::Schema.renderer('app/views/api/v1', locals: { current_user: @user })
jbuilder.yaml @article, title: 'Article', description: 'Article in the blog'
```

#### Rendering Templates

For templates like `app/views/articles/index.jbuilder`, specify the template path and variables:

```ruby
Jbuilder::Schema.yaml(template: "articles/index", assigns: { articles: Article.first(3) })
```

### Output

Jbuilder::Schema automatically sets `description`, `type`, and `required` fields in the JSON Schema. You can *[customize](#customization)* these using the `schema:` hash.

#### Example

```ruby
# _article.json.jbuilder
json.extract! article, :id, :title, :body, :created_at
```

#### Result

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
    type: integer
    description: Article ID
  title:
    type: string
    description: Article Title
  body:
    type: string
    description: Article Contents
  created_at:
    type:
      - string
      - "null"
    format: date-time
    description: Timestamp when article was created
```

### Handling Arrays and Objects

The gem efficiently handles arrays and objects, including nested structures. Arrays with a single element type are straightforwardly represented, while arrays with mixed types use the `anyOf` keyword for versatility.

Support of various object types like `Hash`, `Struct`, `OpenStruct`, and `ActiveRecord::Base` is also integrated. It simplifies object schemas by setting only type and properties.

#### Example

```ruby
json.custom_array [1, article.user, 2, "Text", [3.14, 25.44], 5.33, [4, "Another text", {z: 7, x: "SDR"}], {a: 1, b: "Test"}, {c: 2, d: {z: 3, x: "b"}}]
```

#### Result

```yaml
properties:
  custom_array:
    type:
      - array
      - "null"
    minContains: 0
    contains:
      anyOf:
        - type: integer
        - type: object
          # ... ActiveRecord object properties ...
        - type: string
        - type: array
          # All arrays are merged in one so all possible values of arrays are in one place
          minContains: 0
          contains:
            anyOf:
              - type: number
              - type: integer
              - type: string
              - type: object
                # ... object properties ...
        - type: number
        # ... additional types ...
        - type: object
          properties:
            a:
              type: integer
              # ... description ...
            b:
              type: integer
              # ... description ...
        - type: object
          properties:
            c:
              type: integer
              # ... description ...
            d:
              type: object
              properties:
                z:
                  type: integer
                  # ... description ...
                x:
                  type: string
                  # ... description ...
```

Each schema is unique, ensuring no duplication. Description fields are nested under parent field names for clarity.

### Customization

Customize individual or multiple fields at once using the `schema:` attribute.
For nested objects and collections, use the `schema: {object: <nested_object>}` format.

#### Example

```ruby
json.id article.id, schema: { type: :number, description: "Custom ID description" }
json.title article.title, schema: { minLength: 5, maxLength: 20 }
json.contents article.body, schema: { type: :text, maxLength: 500, required: true }
json.created_at article.created_at.strftime('%d/%m/%Y'), schema: { format: :date, pattern: /^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$/ }

json.author schema: {object: article.user, title: "Article Author", description: "The person who wrote the article", required: true} do
  json.extract! article.user, :id, :name, :email, schema: {id: {type: :string}, email: {type: :email, pattern: /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/}}
end
```

#### Result

```yaml
type: object
title: Article
description: Article in the blog
required:
  - id
  - title
  - contents
  - author
properties:
  id:
    type: number
    description: Custom ID description
  title:
    type: string
    minLength: 5
    maxLength: 20
    description: Title of an article
  contents:
    type: string
    maxLength: 500
    description: Contents of an article
  created_at:
    type:
      - string
      - "null"
    format: date
    pattern: "^(3[01]|[12][0-9]|0[1-9])\/(1[0-2]|0[1-9])\/[0-9]{4}$"
    description: Timestamp when article was created
  author:
    type: object
    title: Article Author
    description: The person who wrote the article
    required:
      - id
      - name
      - email
    properties:
      id:
        type: string
        description: User ID
      name:
        type: string
        description: User Name
      email:
        type: email
        pattern: "^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"
        description: User Email
```

### Nested Partials and Arrays

Nested partials and arrays will most commonly produce reference to the related schema component.
Only if block with partial includes other fields, the inline object will be generated.

#### Example

```ruby
json.author do
  json.partial! "api/v1/users/user", user: article.user
end
json.comments do
  json.array! article.comments, partial: "api/v1/articles/comments/comment", as: :article_comment
end
```

#### Result

```yaml
# ... object description ...
properties:
  author:
    type: object
    allOf:
      - "$ref": "#/components/schemas/User"
    description: User
  comments:
    type: array
    items:
      - "$ref": "#/components/schemas/Comment"
    description: Comment
```

Reference name is taken from `:as` option or first of the `locals:`.

The path to component schemas can be configured with `components_path` variable, which defaults to `components/schemas`. See *[Configuration](#configuration)* for more info.

### Titles & Descriptions

Set custom titles and descriptions directly or through locale files. For models, use `<underscored_plural_model_name>.<title_name>` and for fields, use `<underscored_plural_model_name>.fields.<field_name>.<description_name>` in locale files:

```yaml
en:
  articles:
    title: Article
    description: The main object on the blog
    fields:
      title:
        description: The title of an article
```

### Configuration

Configure Jbuilder::Schema in `config/initializers/jbuilder_schema.rb`:

```ruby
Jbuilder::Schema.configure do |config|
  config.components_path = "components/schemas"   # could be "definitions/schemas"
  config.title_name = "title"                     # could be "label"
  config.description_name = "description"         # could be "heading"
end
```

### Integration with RSwag

Use `yaml`/`json` methods in your `swagger_helper.rb` for Swagger documentation:

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

Contributions are welcome! Report bugs and submit pull requests on [GitHub](https://github.com/bullet-train-co/jbuilder-schema).

## License

This gem is open source under the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
