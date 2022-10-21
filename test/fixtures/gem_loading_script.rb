require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem "jbuilder"
  gem "jbuilder-schema", path: "../jbuilder-schema"
end

article = Struct.new(:id, :title, :body, :created_at, :updated_at).new(1, "yo", "sup", DateTime.now, DateTime.now)

puts Jbuilder::Schema.yaml "api/v1/articles/_article", paths: ["test/fixtures"], locals: { article: article }
