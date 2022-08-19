# JbuilderSchema

Generate JSON Schema from Jbuilder files

## Installation

In Gemfile put `gem 'jbuilder-schema'` **before** `gem 'jbuilder'`:

    gem 'jbuilder-schema', require: 'jbuilder/schema'
    gem 'jbuilder'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jbuilder-schema

## Usage

Wherever you want to generate schemas, you should extend `JbuilderSchema::Helpers`:

    extend JbuilderSchema::Helpers

Then you can use `jbuilder_schema` helper:

    jbuilder_schema('api/v1/articles/_article',
                    model: Article,
                    title: 'Article',
                    description: 'Show action for 1 article in the blog',
                    locals: {
                      article: FactoryBot.create(:article),
                      current_user: FactoryBot.create(:user, admin: true)
                    })

`jbuilder_schema` helper takes path to Jbuilder template as a first argument and several optional arguments:

- `model`: Model described in template, this is needed to populate `required` field in schema
- `title` and `description`: Title and description of schema
- `locals`: Here you should pass all the locals which are met in the template. Those could be any objects as long as they respond to methods called on them in template.

**Schema is produced in ruby Hash, so you can call `.as_json`/`.to_json` on it if you want it in pure JSON.**

### Collections

If array of objects is generated in template, either in root or in some field through Jbuilder partials, JSON-Schema `$ref` is generated pointing to object with the same name as partial. By default those schemas should appear in `"#/components/schemas/"`.

For example, if we have:

    json.user do
      json.partial! 'api/v1/users/user', user: user

      json.articles do
        json.array! user.articles, partial: "api/v1/articles/article", as: :article
      end
    end

The result would be:

    "user": {
      "type": "object",
      "$ref": "#/components/schemas/user",
      "articles": {
        "type": "array",
        "items": {
          "$ref": "#/components/schemas/article"
        }
      }
    }

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This gem is still in early development, so **it's not really recommended for production** yet. At least tests are to be done :)

Bug reports and pull requests are welcome on GitHub at https://github.com/newstler/jbuilder-schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
