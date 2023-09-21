require "bundler/inline"

# Require what Bundler won't activate for us.
require "bigdecimal"

gemfile do
  source "https://rubygems.org"

  gem "jbuilder"
  gem "jbuilder-schema", path: "../jbuilder-schema"
end

user = Struct.new(:id, :name, :email, :created_at, :updated_at).new(1, "John", "john@example.com", Time.now, Time.now)

puts Jbuilder::Schema.renderer(["test/fixtures/app/views/api/v1", "test/fixtures/app/views"]).yaml partial: "api/v1/users/user", object: user
