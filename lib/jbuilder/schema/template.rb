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
      def self.build(object: nil, object_title: nil, object_description: nil, **)
        new(model: object.class, title: object_title, description: object_description)
      end

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
      @configuration = Configuration.new(**options)

      super(context)

      @ignore_nil = false
    end

    def target!
      schema!
    end

    def schema!
      @type == :object ? _object(attributes!) : attributes!
    end

    def set!(key, value = BLANK, *args, schema: nil, **options, &block)
      old_configuration, @configuration = @configuration, Configuration.build(**schema) if schema&.dig(:object)

      _with_schema_overrides(key => schema) do
        @inline_array = true if block && _blank?(value) || _is_collection?(value)

        super(key, value, *args.presence || _extract_possible_keys(value), **options, &block)
      end
    ensure
      @configuration = old_configuration if old_configuration
    end

    def array!(collection = [], *args, schema: nil, **options, &block)
      if _partial_options?(options)
        partial!(collection: collection, **options)
      else
        @type = :array

        _with_schema_overrides(schema) do
          @attributes = {} if blank?
          @attributes[:type] = :array unless ::Kernel.block_given?
          @attributes[:items] = _scope { super(collection, *args, &block) }
        end
      end
    end

    def extract!(object, *attributes, schema: nil)
      _with_schema_overrides(schema) { super(object, *attributes) }
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

    def _extract_possible_keys(value)
      value.first.as_json.keys if _is_collection?(value) && _is_active_model?(value.first)
    end

    def _with_schema_overrides(overrides)
      old_schema_overrides, @schema_overrides = @schema_overrides, overrides if overrides
      yield
    ensure
      @schema_overrides = old_schema_overrides if overrides
    end

    def _object(attributes)
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
      ref = {"$ref": "#/#{::Jbuilder::Schema.components_path}/#{part.split("/").last}"}
      @attributes = {} if _blank?

      case
      when !@inline_array
        @type = :array
        @attributes[:items] = ref
      when collection&.any?
        @attributes.merge! type: :array, items: ref
      else
        @attributes.merge! type: :object, **ref
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
      _set_description(key, value)
      super
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

    def _merge_block(key)
      current_value = _blank? ? BLANK : @attributes.fetch(_key(key), BLANK)
      raise NullError.build(key) if current_value.nil?

      value = _scope { yield self }
      value = _object(value) unless value[:type] == :array || value.key?(:$ref)
      _merge_values(current_value, value)
    end
  end
end
