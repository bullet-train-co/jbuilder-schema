json.extract! comment,
  :text

json.author do
  json.partial! "api/v1/users/user", user: comment.user
end
