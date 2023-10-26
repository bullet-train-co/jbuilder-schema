json.partial! "api/v1/shared/id", resource: user

json.extract! user,
  :name,
  :email,
  :created_at,
  :updated_at

# Array of partials with :collection parameter in block
json.articles do
  json.partial! "api/v1/articles/title", collection: user.articles, as: :article
end

# Array of partials in array block with collection passed to root key
json.comments user.comments do |comment|
  json.partial! "api/v1/articles/comments/text", comment: comment
end
