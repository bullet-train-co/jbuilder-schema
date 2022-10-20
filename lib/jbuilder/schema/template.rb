# frozen_string_literal: true

require "jbuilder/jbuilder_template"
require "active_support/inflections"
require "active_support/core_ext/hash/deep_transform_values"

module JbuilderSchema
  # Template parser class
  class Template < ::JbuilderTemplate
    attr_reader :attributes, :type, :models, :titles, :descriptions

    def initialize(*args, **options)
      @type = :object
      @inline_array = false
      @collection = false

      @models = [options.delete(:model)]
      @titles = [options.delete(:title)]
      @descriptions = [options.delete(:description)]

      super(nil, *args)

      @ignore_nil = false
    end

    def schema!
      {type: type}.merge(type == :object ? _object(**attributes.merge) : attributes)
    end

    def set!(key, value = BLANK, *args, **schema_options, &block)
      result = if block
        if !_blank?(value)
          # OBJECTS ARRAY:
          # json.comments @article.comments { |comment| ... }
          # { "comments": [ { ... }, { ... } ] }
          _scope { array! value, &block }
        else
          # BLOCK:
          # json.comments { ... }
          # { "comments": ... }
          @inline_array = true
          if schema_options.key?(:object)
            models << schema_options[:object].class
            titles << schema_options[:object_title] || nil
            descriptions << schema_options[:object_description] || nil
          end
          r = _merge_block(key) { yield self }
          if schema_options.key?(:object)
            models.pop
            titles.pop
            descriptions.pop
          end
          r
        end
      elsif args.empty?
        if ::Jbuilder === value
          # ATTRIBUTE1:
          # json.age 32
          # json.person another_jbuilder
          # { "age": 32, "person": { ...  }
          _schema(key, _format_keys(value.attributes!), **schema_options)
        elsif _is_collection_array?(value)
          # ATTRIBUTE2:
          _scope { array! value }
        # json.articles @articles
        else
          # json.age 32
          # { "age": 32 }
          _schema(key, _format_keys(value), **schema_options)
        end
      elsif _is_collection?(value)
        # COLLECTION:
        # json.comments @article.comments, :content, :created_at
        # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
        @inline_array = true
        @collection = true

        _scope { array! value, *args }
      elsif schema_options.key?(:object)
        # EXTRACT!:
        # json.author @article.creator, :name, :email_address
        # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }

        models << schema_options.delete(:object).class
        titles << schema_options.delete(:object_title) || nil
        descriptions << schema_options.delete(:object_description) || nil
        r = _merge_block(key) { extract! value, *args, **schema_options }
        models.pop
        titles.pop
        descriptions.pop
        r
      else
        _merge_block(key) { extract! value, *args, **schema_options }
      end

      result = _set_description key, result if models.any?
      _set_value key, result
    end

    def extract!(object, *attributes, **schema_options)
      schema_options = schema_options[:schema] if schema_options.key?(:schema)

      if ::Hash === object
        _extract_hash_values(object, attributes, **schema_options)
      else
        _extract_method_values(object, attributes, **schema_options)
      end
    end

    def array!(collection = [], *args, &block)
      args, schema_options = _args_and_schema_options(*args)
      options = args.first

      if args.one? && _partial_options?(options)
        @collection = true
        _set_ref(options[:partial].split("/").last)
      else
        array = _make_array(collection, *args, **schema_options, &block)

        if @inline_array
          @attributes = {}
          _set_value(:type, :array)
          _set_value(:items, array)
        elsif _is_collection_array?(array)
          @attributes = {}
          @inline_array = true
          @collection = true
          array! array, *array.first&.attribute_names(&:to_sym)
        else
          @type = :array
          @attributes = {}
          _set_value(:items, array)
        end
      end
    end

    def partial!(*args)
      if args.one? && _is_active_model?(args.first)
        # TODO: Find where it is being used
        _render_active_model_partial args.first
      elsif args.first.is_a?(Hash)
        _set_ref(args.first[:partial].split("/").last)
      else
        @collection = true if args[1].key?(:collection)
        _set_ref(args.first&.split("/")&.last)
      end
    end

    def merge!(object)
      hash_or_array = ::Jbuilder === object ? object.attributes! : object
      hash_or_array = _format_keys(hash_or_array)
      if hash_or_array.is_a?(Hash)
        hash_or_array = hash_or_array.each_with_object({}) do |(key, value), a|
          result = _schema(key, value)
          result = _set_description(key, result) if models.any?
          a[key] = result
        end
      end
      @attributes = _merge_values(@attributes, hash_or_array)
    end

    def cache!(key = nil, **options)
      yield
    end

    def method_missing(*args, &block)
      args, schema_options = _args_and_schema_options(*args)

      if block
        set!(*args, **schema_options, &block)
      else
        set!(*args, **schema_options)
      end
    end

    private

    def _object(**attributes)
      title = titles.last || ::I18n.t("#{models&.last&.name&.underscore&.pluralize}.#{JbuilderSchema.configuration.title_name}")
      description = descriptions.last || ::I18n.t("#{models&.last&.name&.underscore&.pluralize}.#{JbuilderSchema.configuration.description_name}")
      {
        type: :object,
        title: title,
        description: description,
        required: _required!(attributes.keys),
        properties: attributes
      }
    end

    def _args_and_schema_options(*args)
      schema_options = args.extract! { |a| a.is_a?(::Hash) && a.key?(:schema) }.first.try(:[], :schema) || {}
      [args, schema_options]
    end

    def _set_description(key, value)
      unless value.key?(:description)
        description = ::I18n.t("#{models.last&.name&.underscore&.pluralize}.fields.#{key}.#{JbuilderSchema.configuration.description_name}")
        value = {description: description}.merge! value
      end
      value
    end

    def _set_ref(component)
      if @inline_array
        if @collection
          _set_value(:type, :array)
          _set_value(:items, {:$ref => _component_path(component)})
        else
          _set_value(:type, :object)
          _set_value(:$ref, _component_path(component))
        end
      else
        @type = :array
        _set_value(:items, {:$ref => _component_path(component)})
      end
    end

    def _component_path(component)
      "#/#{JbuilderSchema.configuration.components_path}/#{component}"
    end

    def _schema(key, value, **options)
      options.merge!(_guess_type(value)) unless options[:type]
      options.merge!(_set_enum(key.to_s)) if models.last&.defined_enums&.keys&.include?(key.to_s)
      options
    end

    def _guess_type(value)
      type = value.class.name&.downcase&.to_sym

      case type
      when :datetime, :"activesupport::timewithzone"
        {type: :string, format: "date-time"}
      when :time, :date
        {type: :string, format: type.to_s}
      when :array
        _guess_array_types(value)
      else
        {type: _type(type)}
      end
    end

    def _guess_array_types(array)
      hash = {type: :array}
      types = array.map { |a| _type(a.class.name&.downcase&.to_sym) }.uniq

      unless types.empty?
        hash[:contains] = {type: types.size > 1 ? types : types.first}
        hash[:minContains] = 0
      end

      hash
    end

    def _type(type)
      case type
      when :float, :bigdecimal
        :number
      when :trueclass, :falseclass
        :boolean
      when :integer
        :integer
      else
        :string
      end
    end

    def _set_enum(key)
      enums = models.last&.defined_enums[key].keys
      {enum: enums}
    end

    def _make_array(collection, *args, **schema_options, &block)
      if collection.nil?
        []
      elsif block
        _map_collection(collection, &block)
      elsif args.any?
        _map_collection(collection) { |element| extract! element, *args, **schema_options }
      else
        _format_keys(collection.to_a)
      end
    end

    def _is_collection_array?(object)
      # TODO: Find better way to determine if all array elements are models
      object.is_a?(Array) && object.map { |a| _is_active_model?(a) }.uniq == [true]
    end

    def _required!(keys)
      presence_validated_attributes = models.last.try(:validators).to_a.flat_map { _1.attributes if _1.is_a?(::ActiveRecord::Validations::PresenceValidator) }
      keys & [_key(:id), *presence_validated_attributes.map { _key _1 }]
    end

    ###
    # Jbuilder methods
    ###

    def _key(key)
      @key_formatter ? @key_formatter.format(key).to_sym : key.to_sym
    end

    def _extract_hash_values(object, attributes, **schema_options)
      attributes.each do |key|
        result = _schema(key, _format_keys(object.fetch(key)), **schema_options[key] || {})
        result = _set_description(key, result) if models.any?
        _set_value key, result
      end
    end

    def _extract_method_values(object, attributes, **schema_options)
      attributes.each do |key|
        result = _schema(key, _format_keys(object.public_send(key)), **schema_options[key] || {})
        result = _set_description(key, result) if models.any?
        _set_value key, result
      end
    end

    def _map_collection(collection)
      super.first
    end

    def _merge_block(key)
      current_value = _blank? ? BLANK : @attributes.fetch(_key(key), BLANK)
      raise NullError.build(key) if current_value.nil?

      new_value = _scope { yield self }
      unless new_value.key?(:type) && new_value[:type] == :array || new_value.key?(:$ref)
        new_value_properties = new_value
        new_value = _object(**new_value_properties)
      end
      _merge_values(current_value, new_value)
    end
  end
end

class Jbuilder
  # Monkey-patch for Jbuilder::KeyFormatter to ignore schema keys
  class KeyFormatter
    alias_method :original_format, :format

    def format(key)
      return key if %i[type items properties].include?(key)

      original_format(key)
    end
  end
end
