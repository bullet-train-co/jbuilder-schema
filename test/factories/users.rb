FactoryBot.define do
  factory :user do
    sequence(:id)
    sequence(:email) { |n| "user-#{n}@example.com" }
    sequence(:name) { |n| "Generic name #{n}" }
  end
end

class User
  attr_accessor :id, :email, :name

  def save!
    true
  end
end
