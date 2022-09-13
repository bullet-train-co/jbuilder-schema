# frozen_string_literal: true

require "bundler/setup"

require "rails"
require "factory_bot"
require "faker"

require "jbuilder"
require "jbuilder/schema"

require "active_support/testing/autorun"
require "mocha/minitest"

ActiveSupport.test_order = :random
ActiveSupport::TimeWithZone.singleton_class.remove_method(:name) # Remove after Rails 7.1 release

FactoryBot.find_definitions

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
