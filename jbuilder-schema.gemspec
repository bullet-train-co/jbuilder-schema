# frozen_string_literal: true

require_relative "lib/jbuilder/schema/version"

Gem::Specification.new do |spec|
  spec.name = "jbuilder-schema"
  spec.version = JBUILDER_SCHEMA_VERSION
  spec.authors = ["Yuri Sidorov"]
  spec.email = ["git@yurisidorov.com"]

  spec.summary = "Generate JSON Schema from Jbuilder files"
  spec.description = spec.summary
  spec.homepage = "https://github.com/bullet-train-co/jbuilder-schema"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "jbuilder"
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "method_source"
  spec.add_dependency "ostruct"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "logger"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
