FactoryBot.define do
  factory :user do
    sequence(:id)
    sequence(:email) { |n| "user-#{n}@example.com" }
    sequence(:name) { |n| "Generic name #{n}" }
  end
end

class User
  attr_accessor :id, :email, :name

  class << self
    def defined_enums
      {}
    end

    def validators
      []
    end
  end

  def save!
    true
  end
end
