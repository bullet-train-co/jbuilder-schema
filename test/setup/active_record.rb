require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
  end

  create_table :articles, force: true do |t|
    t.references :user
    t.string :title, null: false
    t.text :body, null: false
    t.timestamps
  end
end

class User < ActiveRecord::Base
end

5.times do |n|
  User.create! name: "Generic name #{n}", email: "user-#{n}@example.com"
end

class Article < ActiveRecord::Base
  belongs_to :user

  def as_json(options = nil)
    super({only: %i[id title body]}.merge(options || {}))
  end
end

5.times do |n|
  Article.create! user: User.first, title: "Generic title #{n}", body: "Lorem ipsum… #{n}"
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
