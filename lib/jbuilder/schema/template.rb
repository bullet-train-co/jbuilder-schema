# frozen_string_literal: true

require "active_support/inflections"
require "safe_parser"

module JbuilderSchema
  # Template parser class
  class Template
    attr_reader :source, :models

    def initialize(source)
      @source = source
      @models = {}

      Zeitwerk::Loader.eager_load_all if defined?(Zeitwerk::Loader)
    end

    def properties
      _create_properties!
    end

    def required
      _create_required!
    end

    private

    def _lines
      source.to_s
        .split(/\n+|\r+/)
        .reject(&:empty?)
        .reject { |l| l.start_with?("#") }
        .map { |l| l.split("#").first }
    end

    def _parse_lines!
      schema_regexp = ",?\s?schema(:|=>|\s=>)\s?"
      hash_regexp = "{(.*?)}"

      {}.tap do |hash|
        _lines.each_with_index do |line, index|
          hash[index] = {}.tap do |line_hash|
            line_hash[:property] = line.split.first.delete_prefix("json.").to_sym
            schema = line.slice!(/#{schema_regexp + hash_regexp}/)&.strip&.gsub(/#{schema_regexp}/, "") || "{}"
            line_hash[:schema] = SafeParser.new(schema).safe_load
            line_hash[:arguments] = line.split[1..].map { |e| e.delete(",") }
            line_hash[:schema] = _schema_for_line(line_hash)
          end
        end
      end
    end

    def _schema_for_line(line)
      schema = line[:schema]
      unless schema[:type]
        type = _get_type(line[:arguments].first)
        type.is_a?(Array) ? (schema[:type], schema[:format] = type) : schema[:type] = type
      end
      schema
    end

    def _get_type(value)
      klass = :boolean if %w[true false].include?(value)
      klass = :integer if Integer(value, exception: false) && klass.nil?
      klass = :number if Float(value, exception: false) && klass.nil?

      _schematize_type(klass || _type_from_model(value))
    end

    def _schematize_type(type)
      case type
      when :datetime
        [:string, "date-time"]
      when nil, :text
        :string
      else
        type
      end
    end

    def _type_from_model(string)
      variable, method = string.split(".")
      class_name = variable.delete("@").classify

      return unless models.key?(class_name) || _find_class(class_name)

      models[class_name].columns_hash[method].type
    end

    def _find_class(string)
      klass = string.classify.safe_constantize
      return unless klass && klass.respond_to?("columns_hash")

      models[string] = klass
    end

    def _create_properties!
      sorted_hash = _parse_lines!.sort.to_h

      {}.tap do |hash|
        sorted_hash.each do |_index, line|
          hash[line[:property]] = line[:schema]
        end
      end
    end

    def _create_required!
      models.flat_map { |_k, model|
        model.validators.grep(ActiveRecord::Validations::PresenceValidator).flat_map(&:attributes)
      }
    end
  end
end
