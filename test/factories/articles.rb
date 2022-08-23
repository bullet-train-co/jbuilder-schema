# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    sequence(:id) { |n| n }
    title { Faker::Lorem.unique.sentence(word_count: 10).truncate(15) }
    body { Faker::Lorem.paragraph_by_chars(number: 256) }
    created_at { Time.now }
    updated_at { Time.now }
    user
  end
end

class Article
  attr_accessor :id, :title, :body, :created_at, :updated_at, :user_id

  def user=(user)
    self.user_id = user.id
  end

  def save!
    true
  end

  # def as_json(options = nil)
  #   super({ only: [:id, :title, :body] }.merge(options || {}))
  # end
end
