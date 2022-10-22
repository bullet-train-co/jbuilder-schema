# frozen_string_literal: true

require "bundler/setup"

require "rails"

require "jbuilder"
require "jbuilder/schema"

require "active_support/testing/autorun"
require "mocha/minitest"

require "setup/active_record"

ActiveSupport.test_order = :random
ActiveSupport::TimeWithZone.singleton_class.remove_method(:name) # Remove after Rails 7.1 release
