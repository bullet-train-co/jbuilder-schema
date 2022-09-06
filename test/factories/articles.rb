# frozen_string_literal: true

require "active_model/naming"
require "active_model/conversion"

FactoryBot.define do
  factory :article do
    sequence(:id)
    sequence(:title) { |n| "Generic title #{n}" }
    body { Faker::Lorem.paragraph_by_chars(number: 256) }
    created_at { Time.now }
    updated_at { Time.now }
    user
  end
end

class Article
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :id, :title, :body, :created_at, :updated_at, :user_id

  def user=(user)
    self.user_id = user.id
  end

  def save!
    true
  end

  def attribute_names
    instance_variables.map(&:name).map { |v| v.delete_prefix "@" }
  end

  def as_json(options = nil)
    super({only: [:id, :title, :body]}.merge(options || {}))
  end
end
