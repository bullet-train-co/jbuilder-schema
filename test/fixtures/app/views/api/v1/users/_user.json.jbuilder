json.partial! "api/v1/shared/id", resource: user

json.extract! user,
  :name,
  :email,
  :created_at,
  :updated_at

# Array of partials with :collection parameter in block — should be array with refs
json.articles do
  json.partial! "api/v1/articles/article", collection: user.articles, as: :article
  # TODO: Next line produces wrong ref name ("api/v1/articles/title")
  # json.partial! "api/v1/articles/title", collection: user.articles, as: :article
end

# Array of partials in array block with collection passed to root key — should be array with refs
json.comments user.comments do |comment|
  json.partial! "api/v1/articles/comments/text", comment: comment
end
