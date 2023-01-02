# frozen_string_literal: true

require "jbuilder/jbuilder_template"
require "active_support/inflections"

class Jbuilder::Schema
  class Template < ::JbuilderTemplate
    attr_reader :attributes, :type
    attr_reader :model_scope

    class Handler < ::JbuilderHandler
      def self.call(template, source = nil)
        super.sub("JbuilderTemplate.new(self", "Jbuilder::Schema::Template.build(self, local_assigns")
      end
    end

    ::ActiveSupport.on_load :action_view do
      ::ActionView::Template.register_template_handler :jbuilder, ::Jbuilder::Schema::Template::Handler
    end

    def self.build(view_context, local_assigns)
      if (options = local_assigns[:__jbuilder_schema_options])
        new(view_context, **options)
      else
        ::JbuilderTemplate.new(view_context)
      end
    end

    ModelScope = ::Struct.new(:model, :title, :description, keyword_init: true) do
      def initialize(**)
        super
        @scope = model&.name&.underscore&.pluralize
      end

      def i18n_title
        title || ::I18n.t(::Jbuilder::Schema.title_name, scope: @scope)
      end

      def i18n_description
        description || ::I18n.t(::Jbuilder::Schema.description_name, scope: @scope)
      end

      def translate_field(key)
        ::I18n.t("fields.#{key}.#{::Jbuilder::Schema.description_name}", scope: @scope)
      end
    end

    def initialize(context, **options)
      @type = :object
      @inline_array = false
      @collection = false

      @model_scope = ModelScope.new(**options)

      super(context)

      @ignore_nil = false
    end

    def target!
      schema!
    end

    def schema!
      {type: type}.merge(type == :object ? _object(**attributes.merge) : attributes)
    end

    def set!(key, value = BLANK, *args, schema: {}, **options, &block)
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

          _with_model_scope(**schema) do
            _merge_block(key) { yield self }
          end
        end
      elsif args.empty?
        if ::Jbuilder === value
          # ATTRIBUTE1:
          # json.age 32
          # json.person another_jbuilder
          # { "age": 32, "person": { ...  }
          _schema(key, _format_keys(value.attributes!), **schema)
        elsif _is_collection_array?(value)
          # ATTRIBUTE2:
          _scope { array! value }
        # json.articles @articles
        else
          # json.age 32
          # { "age": 32 }
          _schema(key, _format_keys(value), **schema)
        end
      elsif _is_collection?(value)
        # COLLECTION:
        # json.comments @article.comments, :content, :created_at
        # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
        @inline_array = true
        @collection = true

        _scope { array! value, *args }
      else
        # EXTRACT!:
        # json.author @article.creator, :name, :email_address
        # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
        _with_model_scope(**schema) do
          _merge_block(key) { extract! value, *args, schema: schema }
        end
      end

      _set_description key, result
      _set_value key, result
    end

    def extract!(object, *attributes, schema: {})
      if ::Hash === object
        _extract_hash_values(object, attributes, schema: schema)
      else
        _extract_method_values(object, attributes, schema: schema)
      end
    end

    def array!(collection = [], *args, schema: {}, **options, &block)
      if _partial_options?(options)
        @collection = true
        _set_ref(options[:partial].split("/").last)
      else
        array = _make_array(collection, *args, schema: schema, &block)

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
      elsif args.first.is_a?(::Hash)
        _set_ref(args.first[:partial].split("/").last)
      else
        @collection = true if args[1].key?(:collection)
        _set_ref(args.first&.split("/")&.last)
      end
    end

    def merge!(object)
      hash_or_array = ::Jbuilder === object ? object.attributes! : object
      hash_or_array = _format_keys(hash_or_array)
      if hash_or_array.is_a?(::Hash)
        hash_or_array = hash_or_array.each_with_object({}) do |(key, value), a|
          a[key] = _schema(key, value)
        end
      end
      @attributes = _merge_values(@attributes, hash_or_array)
    end

    def cache!(key = nil, **options)
      yield # TODO: Our schema generation breaks Jbuilder's fragment caching.
    end

    def method_missing(*args, **options, &block) # standard:disable Style/MissingRespondToMissing
      # TODO: Remove once Jbuilder passes keyword arguments along to `set!` in its `method_missing`.
      set!(*args, **options, &block)
    end

    private

    def _with_model_scope(object: nil, object_title: nil, object_description: nil, **)
      old_model_scope, @model_scope = @model_scope, ModelScope.new(model: object.class, title: object_title, description: object_description) if object
      yield
    ensure
      @model_scope = old_model_scope if object
    end

    def _object(**attributes)
      {
        type: :object,
        title: model_scope.i18n_title,
        description: model_scope.i18n_description,
        required: _required!(attributes.keys),
        properties: attributes
      }
    end

    def _set_description(key, value)
      if !value.key?(:description) && model_scope.model
        value[:description] = model_scope.translate_field(key)
      end
    end

    def _set_ref(component)
      component_path = "#/#{::Jbuilder::Schema.components_path}/#{component}"

      if @inline_array
        if @collection
          _set_value(:type, :array)
          _set_value(:items, {:$ref => component_path})
        else
          _set_value(:type, :object)
          _set_value(:$ref, component_path)
        end
      else
        @type = :array
        _set_value(:items, {:$ref => component_path})
      end
    end

    FORMATS = {::DateTime => "date-time", ::ActiveSupport::TimeWithZone => "date-time", ::Date => "date", ::Time => "time"}

    def _schema(key, value, **options)
      unless options[:type]
        options[:type] = _primitive_type value

        if options[:type] == :array && (types = value.map { _primitive_type _1 }.uniq).any?
          options[:minContains] = 0
          options[:contains] = {type: types.many? ? types : types.first}
        end

        format = FORMATS[value.class] and options[:format] ||= format
      end

      if (model = model_scope.model) && (defined_enum = model.try(:defined_enums)&.dig(key.to_s))
        options[:enum] = defined_enum.keys
      end

      _set_description key, options
      options
    end

    def _primitive_type(type)
      case type
      when ::Array then :array
      when ::Float, ::BigDecimal then :number
      when true, false then :boolean
      when ::Integer then :integer
      else
        :string
      end
    end

    def _make_array(collection, *args, schema: {}, &block)
      if collection.nil?
        []
      elsif block
        _map_collection(collection, &block)
      elsif args.any?
        _map_collection(collection) { |element| extract! element, *args, schema: schema }
      else
        _format_keys(collection.to_a)
      end
    end

    def _is_collection_array?(object)
      object.is_a?(::Array) && object.all? { _is_active_model? _1 }
    end

    def _required!(keys)
      presence_validated_attributes = model_scope.model.try(:validators).to_a.flat_map { _1.attributes if _1.is_a?(::ActiveRecord::Validations::PresenceValidator) }
      keys & [_key(:id), *presence_validated_attributes.map { _key _1 }]
    end

    ###
    # Jbuilder methods
    ###

    def _extract_hash_values(object, attributes, schema:)
      attributes.each do |key|
        result = _schema(key, _format_keys(object.fetch(key)), **schema[key] || {})
        _set_value key, result
      end
    end

    def _extract_method_values(object, attributes, schema:)
      attributes.each do |key|
        result = _schema(key, _format_keys(object.public_send(key)), **schema[key] || {})
        _set_value key, result
      end
    end

    def _map_collection(collection)
      super.first
    end

    def _merge_block(key)
      current_value = _blank? ? BLANK : @attributes.fetch(_key(key), BLANK)
      raise NullError.build(key) if current_value.nil?

      value = _scope { yield self }
      value = _object(**value) unless value.values_at("type", :type).any?(:array) || value.key?(:$ref) || value.key?("$ref")
      _merge_values(current_value, value)
    end
  end
end

class Jbuilder
  module SkipFormatting
    SCHEMA_KEYS = %i[type items properties]

    def format(key)
      SCHEMA_KEYS.include?(key) ? key : super
    end
  end

  KeyFormatter.prepend SkipFormatting
end
