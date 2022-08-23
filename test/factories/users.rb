FactoryBot.define do
  factory :user do
    sequence(:id) { |n| n }
    sequence(:email) { |n| "user-#{n}@example.com" }
  end
end

class User
  attr_accessor :id, :email

  def save!
    true
  end
end
