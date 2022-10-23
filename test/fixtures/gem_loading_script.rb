require "bundler/inline"

# Require what Bundler won't activate for us.
require "bigdecimal"

gemfile do
  source "https://rubygems.org"

  gem "jbuilder"
  gem "jbuilder-schema", path: "../jbuilder-schema"
end

article = Struct.new(:id, :status, :title, :body, :created_at, :updated_at).new(1, "pending", "yo", "sup", Time.now, Time.now)

puts Jbuilder::Schema.yaml partial: "articles/article", paths: ["test/fixtures/api/v1"], object: article
