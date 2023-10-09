# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in jbuilder-schema.gemspec
gemspec

gem "rake", "~> 13.0"

gem "sqlite3"

gem "standard", "~> 1.3"

gem "mocha"

rails_version = ENV.fetch("RAILS_VERSION", "7.0")

rails_constraint = if rails_version == "main"
  {github: "rails/rails"}
else
  "~> #{rails_version}.0"
end

gem "rails", rails_constraint
