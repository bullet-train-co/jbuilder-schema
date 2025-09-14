json.partial! "api/v1/ratings/value", rating: rating

# Inline object partial — should be a ref
json.author rating.user, partial: "api/v1/users/name", as: :user

# Object with many meaningful lines — should be array with object schemas
json.comments [rating.article.comments.first], schema: { object: rating.article.comments.first } do |comment|
  json.partial! "api/v1/articles/comments/text", comment: comment
  json.count rating.article.comments.count
end

