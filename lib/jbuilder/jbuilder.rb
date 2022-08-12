# frozen_string_literal: true

require "jbuilder"

# Patches for Jbuilder to make it ignore schema metadata
class Jbuilder
  alias original_method_missing method_missing

  def method_missing(*args, &block)
    args = _extract_schema_meta!(*args)
    original_method_missing(*args, &block)
  end

  private

  def _extract_schema_meta!(*args)
    args.delete_if { |a| a.is_a?(::Hash) && a.key?(:schema) }
  end
end
