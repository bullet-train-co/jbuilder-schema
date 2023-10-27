json.partial! "api/v1/ratings/value", rating: rating

# Inline object partial — should be a ref
json.author rating.user, partial: "api/v1/users/name", as: :user

# Object with many meaningful lines — should be array with object schemas
json.comments schema: {object: rating.article.comments.first} do
  json.partial! "api/v1/articles/comments/text", comment: rating.article.comments.first
  json.count rating.article.comments.count
end
