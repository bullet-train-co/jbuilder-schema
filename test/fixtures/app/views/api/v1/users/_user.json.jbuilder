json.partial! "api/v1/shared/id", resource: user

json.extract! user,
  :name,
  :email,
  :created_at,
  :updated_at
