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
end

class User < ActiveRecord::Base
end

5.times do |n|
  User.create! name: "Generic name #{n}", email: "user-#{n}@example.com"
end

class Article < ActiveRecord::Base
  belongs_to :user

  enum :status, %i[ pending published archived ]
end

5.times do |n|
  Article.create! user: User.first, title: "Generic title #{n}", body: "Lorem ipsum… #{n}"
end
