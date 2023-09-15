require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Set so Active Record casts created_at/updated_at to ActiveSupport::TimeWithZone.
# Matches Rails apps' default, where `time_zone_aware_attributes` is set via Active Record's railtie:
# https://github.com/rails/rails/blob/a7902034089e8b6bff747c08d93eeac4b1377032/activerecord/lib/active_record/railtie.rb#L84
Time.zone = "UTC"
ActiveRecord::Base.time_zone_aware_attributes = true

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.timestamps null: false
  end

  create_table :articles, force: true do |t|
    t.references :user
    t.string :status, default: "pending", null: false
    t.string :title, null: false
    t.text :body, null: false
    t.timestamps null: false
  end

  create_table :ratings, force: true do |t|
    t.references :user
    t.references :article
    t.integer :value, null: false
    t.timestamps null: false
  end

  create_table :comments, force: true do |t|
    t.references :user
    t.references :article
    t.text :text, null: false
    t.timestamps null: false
  end
end

class User < ActiveRecord::Base
  has_many :articles
  has_many :ratings
  has_many :comments
end

time = DateTime.parse("2023-1-1 12:00")

3.times do |n|
  User.create! name: "Generic name #{n}", email: "user-#{n}@example.com", created_at: time, updated_at: time
end

class Article < ActiveRecord::Base
  belongs_to :user
  has_many :ratings
  has_many :comments

  enum :status, %w[pending published archived].index_by(&:itself)
end

class Rating < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
end

3.times do |n|
  User.first.articles.create! title: "Generic title #{n}", body: "Lorem ipsum… #{n}", created_at: time, updated_at: time
end

Article.all.each do |article|
  3.times do |n|
    article.ratings.create! value: 5 - n, user: User.find(n + 1), created_at: time, updated_at: time
    article.comments.create! text: "Lorem ipsum… #{n}", user: User.find(3 - n), created_at: time, updated_at: time
  end
end
