json.partial! "api/v1/shared/id", resource: article

json.extract! user,
  :name,
  :email,
  :created_at,
  :updated_at
