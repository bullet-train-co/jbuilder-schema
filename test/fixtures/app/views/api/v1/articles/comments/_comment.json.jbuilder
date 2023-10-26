json.partial! "api/v1/articles/comments/text", comment: comment

json.author do
  # Partial in block with extra unmeaningful lines (like comments, empty lines, spaces, e.t.c), with locals — should be a ref
  json.partial! "api/v1/users/name", user: comment.user

end

# Array of partials with many meaningful lines — should be array with object schemas
json.ratings do
  json.array! comment.article.ratings do |rating|
    json.partial! "api/v1/ratings/value", rating: rating
    json.count comment.article.ratings.count
  end
end
