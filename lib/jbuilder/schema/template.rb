# frozen_string_literal: true

require "active_support/inflections"
require "safe_parser"

module JbuilderSchema
  # Template parser class
  # =====================
  #
  # Here we do the following:
  #
  # ✅ Direct fields definition:
  #    json.title @article.title
  #    json.url article_url(@article, format: :json)
  #    json.custom 123
  #
  # ⛔ Relations:
  #    json.user_name @article.user.name
  #    json.comments @article.comments, :content, :created_at
  #
  # ⛔ Collections:
  #    json.comments @comments, :content, :created_at
  #    json.people my_array
  #
  # ⛔️ Blocks:
  #    json.author do
  #      json.name @article.user.name
  #      json.email @article.user.email
  #      json.url url_for(@article.user, format: :json)
  #    end
  #
  #    json.attachments @article.attachments do |attachment|
  #      json.filename attachment.filename
  #      json.url url_for(attachment)
  #    end
  #
  # ⛔️ Conditions:
  #    if current_user.admin?
  #      json.visitors calculate_visitors(@article)
  #    end
  #
  # ⛔️ Ruby code:
  #    hash = { author: { name: "David" } }
  #
  # ⛔️ Jbuilder commands:
  #    json.set! :name, 'David'
  #    json.merge! { author: { name: "David" } }
  #    json.array! @people, :id, :name
  #    json.array! @posts, partial: 'posts/post', as: :post
  #    json.partial! 'comments/comments', comments: @message.comments
  #    json.partial! partial: 'articles/article', collection: @articles, as: :article
  #    json.comments @article.comments, partial: 'comments/comment', as: :comment
  #    json.extract! @article, :id, :title, :content, :published_at
  #    json.key_format! camelize: :lower
  #    json.deep_format_keys!
  #
  # ⛔️ Ignore (?) some of them:
  #    json.ignore_nil!
  #    json.cache! ['v1', @person], expires_in: 10.minutes {}
  #    json.cache_if! !admin?, ['v1', @person], expires_in: 10.minutes {}
  #    json.key_format! camelize: :lower
  #
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
      _parse_lines! if models.empty?
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
      puts ">>>MODELS #{models}"
      models.flat_map { |_k, model|
        model.validators.grep(ActiveRecord::Validations::PresenceValidator).flat_map(&:attributes)
      }
    end
  end
end
