json.extract! rating,
  :value

json.author do
  json.partial! rating.user
end
