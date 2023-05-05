json.extract! article,
  :id,
  :status,
  :title,
  :body,
  :created_at,
  :updated_at,
  schema: {
    body: {
      type: :string, pattern: /\w+/
    }
  }
