# frozen_string_literal: true

require "jbuilder/jbuilder_template"
require "active_support/inflections"

class Jbuilder::Schema
  class Template < ::JbuilderTemplate
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

    class Configuration < ::Struct.new(:model, :title, :description, keyword_init: true)
      def title
        super || translate(Jbuilder::Schema.title_name)
      end

      def description
        super || translate(Jbuilder::Schema.description_name)
      end

      def translate_field(key)
        translate("fields.#{key}.#{Jbuilder::Schema.description_name}")
      end

      private
      def translate(key)
        I18n.t(key, scope: @scope ||= model&.name&.underscore&.pluralize)
      end
    end

    def initialize(context, **options)
      @type = :object
      @inline_array = false

      @configuration = Configuration.new(**options)

      super(context)

      @ignore_nil = false
    end

    def target!
      schema!
    end

    def schema!
      {type: @type}.merge(@type == :object ? _object(**attributes!.merge) : attributes!)
    end

    def set!(key, value = BLANK, *args, schema: {}, **options, &block)
      result = if block
        if !_blank?(value)
          # json.comments @article.comments { |comment| ... }
          # { "comments": [ { ... }, { ... } ] }
          _scope { array! value, &block }
        else
          # json.comments { ... }
          # { "comments": ... }
          @inline_array = true
          _merge_schema_block(key, **schema) { yield self }
        end
      elsif args.empty?
        if value.respond_to?(:all?) && value.all? { _is_active_model? _1 }
          # json.articles @articles # TODO: Jbuilder doesn't automatically extract keys from a collection, should we add this feature?
          _scope { array! value, *value.first.attribute_names }
        else
          # json.age 32
          # json.person another_jbuilder
          # { "age": 32, "person": { ...  }
          value = ::Jbuilder === value ? value.attributes! : value
          _schema(key, _format_keys(value), **schema)
        end
      elsif _is_collection?(value)
        # json.comments @article.comments, :content, :created_at
        # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
        @inline_array = true
        _scope { array! value, *args }
      else
        # json.author @article.creator, :name, :email_address
        # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
        _merge_schema_block(key, **schema) { extract! value, *args, schema: schema }
      end

      _set_description key, result
      _set_value key, result
    end

    def extract!(object, *attributes, schema: {})
      _with_schema_overrides(schema) { super(object, *attributes) }
    end

    def _with_schema_overrides(overrides)
      old_schema_overrides, @schema_overrides = @schema_overrides, overrides
      yield
    ensure
      @schema_overrides = old_schema_overrides
    end

    def array!(collection = [], *args, schema: {}, **options, &block)
      if _partial_options?(options)
        partial!(collection: collection, **options)
      else
        @type = :array

        @attributes = {} if _blank?
        @attributes[:type] = :array unless ::Kernel.block_given?
        @attributes[:items] = _make_array(collection, *args, schema: schema, &block)
      end
    end

    def partial!(model = nil, *args, partial: nil, collection: nil, **options)
      if args.none? && _is_active_model?(model)
        # TODO: Find where it is being used
        _render_active_model_partial model
      else
        _set_ref(partial || model, collection: collection)
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

    def _object(**attributes)
      {
        type: :object,
        title: @configuration.title,
        description: @configuration.description,
        required: _required!(attributes.keys),
        properties: attributes
      }
    end

    def _set_description(key, value)
      if !value.key?(:description) && @configuration.model
        value[:description] = @configuration.translate_field(key)
      end
    end

    def _set_ref(part, collection:)
      component_path = "#/#{::Jbuilder::Schema.components_path}/#{part.split("/").last}"
      @attributes = {} if _blank?

      if @inline_array
        if collection&.any?
          @attributes.merge! type: :array, items: {"$ref": component_path}
        else
          @attributes.merge! type: :object, "$ref": component_path
        end
      else
        @type = :array
        @attributes[:items] = {"$ref": component_path}
      end
    end

    FORMATS = {::DateTime => "date-time", ::ActiveSupport::TimeWithZone => "date-time", ::Date => "date", ::Time => "time"}

    def _schema(key, value, **options)
      options = @schema_overrides&.dig(key).to_h if options.empty?

      unless options[:type]
        options[:type] = _primitive_type value

        if options[:type] == :array && (types = value.map { _primitive_type _1 }.uniq).any?
          options[:minContains] = 0
          options[:contains] = {type: types.many? ? types : types.first}
        end

        format = FORMATS[value.class] and options[:format] ||= format
      end

      if (model = @configuration.model) && (defined_enum = model.try(:defined_enums)&.dig(key.to_s))
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

    def _set_value(key, value)
      value = _schema(key, value) unless value.is_a?(::Hash) && value.key?(:type)
      super
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

    def _required!(keys)
      presence_validated_attributes = @configuration.model.try(:validators).to_a.flat_map { _1.attributes if _1.is_a?(::ActiveRecord::Validations::PresenceValidator) }
      keys & [_key(:id), *presence_validated_attributes.map { _key _1 }]
    end

    ###
    # Jbuilder methods
    ###

    def _map_collection(collection)
      super.first
    end

    def _merge_schema_block(key, object: nil, object_title: nil, object_description: nil, **, &block)
      old_configuration, @configuration = @configuration, Configuration.new(model: object.class, title: object_title, description: object_description) if object
      _merge_block(key, &block)
    ensure
      @configuration = old_configuration if object
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
