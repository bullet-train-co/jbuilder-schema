json.extract! article,
  :id,
  :status,
  :title,
  :body,
  schema: {
    body: {
      type: :string, pattern: /\w+/
    }
  }

json.author article.user, partial: "api/v1/users/user", as: :user

json.ratings article.ratings, partial: "api/v1/ratings/rating", as: :rating

json.comments do
  json.array! article.comments, partial: "api/v1/comments/comment", as: :comment
end
