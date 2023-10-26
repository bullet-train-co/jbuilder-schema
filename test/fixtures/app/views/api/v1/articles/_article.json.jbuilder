# Shared partials
json.partial! "api/v1/shared/id", resource: article
json.partial! "api/v1/articles/title", article: article

json.extract! article,
  :status,
  :body,
  schema: {
    body: {
      type: :string, pattern: /\w+/
    }
  }

# Partial in block only with object and no arguments
json.author do
  json.partial! article.user
end

# Inline array partial
json.ratings article.ratings, partial: "api/v1/ratings/rating", as: :rating

# Array partial with deep name in block
json.comments do
  json.array! article.comments, partial: "api/v1/articles/comments/comment", as: :comment
end
