# frozen_string_literal: true

require "bundler/setup"

require "rails"

require "jbuilder"
Jbuilder::Railtie.run_initializers

require "jbuilder/schema"

require "active_support/testing/autorun"
require "mocha/minitest"

require "setup/active_record"

ActiveSupport.test_order = :random
ActiveSupport::TestCase.file_fixture_path = "test/fixtures"

# In debug mode uncomment this string to have ::Rails.logger available
# ::Rails.logger = ::Logger.new($stdout)
