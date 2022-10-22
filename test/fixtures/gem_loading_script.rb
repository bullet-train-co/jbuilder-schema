require "bundler/inline"

require "bigdecimal"

gemfile do
  source "https://rubygems.org"

  gem "jbuilder"
  gem "jbuilder-schema", path: "../jbuilder-schema"
end

article = Struct.new(:id, :status, :title, :body, :created_at, :updated_at).new(1, "pending", "yo", "sup", DateTime.now, DateTime.now)

puts Jbuilder::Schema.yaml "api/v1/articles/_article", paths: ["test/fixtures"], locals: { article: article }
