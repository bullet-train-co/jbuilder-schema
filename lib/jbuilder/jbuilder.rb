# frozen_string_literal: true

module JbuilderIgnoreSchemaMeta
  def method_missing(*args, schema: nil, **options, &block) # standard:disable Style/MissingRespondToMissing
    super(*args, **options, &block)
  end
end

Jbuilder.prepend JbuilderIgnoreSchemaMeta
