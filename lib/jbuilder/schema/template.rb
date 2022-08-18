# frozen_string_literal: true

require "jbuilder/jbuilder_template"
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
  # ⛔️ Main app helpers:
  #    json.title human_title(@article.title)
  #
  # ✅ Relations:
  #    json.user_name @article.user.name
  #    json.comments @article.comments, :content, :created_at
  #
  # ✅ Collections:
  #    json.comments @comments, :content, :created_at
  #    json.people my_array
  #
  # ✅ Blocks:
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
  # ✅️ Conditions:
  #    if current_user.admin?
  #      json.visitors calculate_visitors(@article)
  #    end
  #
  # ✅️ Ruby code:
  #    hash = { author: { name: "David" } }
  #
  # ✅ Jbuilder commands:
  # ✅ json.set! :name, 'David'
  # ✅ json.merge! { author: { name: "David" } }
  # ✅ json.array! @articles, :id, :title
  # ✅ json.array! @articles, partial: 'articles/article', as: :article
  # ✅ json.partial! 'comments/comments', comments: @message.comments
  # ✅ json.partial! partial: 'articles/article', collection: @articles, as: :article
  # ✅ json.comments @article.comments, partial: 'comments/comment', as: :comment
  # ✅ json.extract! @article, :id, :title, :content, :published_at
  # ✅ json.key_format! camelize: :lower
  # ✅ json.deep_format_keys!
  #
  # ⛔️ Ignore (?) some of them:
  # ✅ json.ignore_nil!
  #    json.cache! ['v1', @person], expires_in: 10.minutes {}
  #    json.cache_if! !admin?, ['v1', @person], expires_in: 10.minutes {}
  #
  class Template < ::JbuilderTemplate
    attr_reader :attributes, :type

    def initialize(context, *args)
      @type = :object
      @inline_array = false
      @collection = false

      super

      @ignore_nil = false
    end

    def set!(key, value = BLANK, *args, &block)
      result = if ::Kernel.block_given?
                 if !_blank?(value)
                   # puts ">>> OBJECTS ARRAY:"
                   # json.comments @article.comments { |comment| ... }
                   # { "comments": [ { ... }, { ... } ] }
                   _scope{ array! value, &block }
                 else
                   # puts ">>> BLOCK:"
                   # json.comments { ... }
                   # { "comments": ... }
                   @inline_array = true
                   _merge_block(key){ yield self }
                 end
               elsif args.empty?
                 if ::Jbuilder === value
                   # puts ">>> ATTRIBUTE1:"
                   # json.age 32
                   # json.person another_jbuilder
                   # { "age": 32, "person": { ...  }
                   _format_keys(value.attributes!)
                 else
                   # puts ">>> ATTRIBUTE2:"
                   # json.age 32
                   # { "age": 32 }
                   _get_type(_format_keys(value))
                 end
               elsif _is_collection?(value)
                 # puts ">>> COLLECTION:"
                 # json.comments @article.comments, :content, :created_at
                 # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
                 @inline_array = true
                 @collection = true
                 _scope{ array! value, *args }
               else
                 # puts ">>> EXTRACT!:"
                 # json.author @article.creator, :name, :email_address
                 # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
                 _merge_block(key){ extract! value, *args }
               end

      _set_value key, result
    end

    def array!(collection = [], *args)
      options = args.first

      if args.one? && _partial_options?(options)
        _set_ref(options[:partial].split("/").last)
      else
        array = super

        if @inline_array
          array
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
      else
        if args.first.is_a?(Hash)
          _set_ref(args.first[:partial].split("/").last)
        else
          @collection = true if args[1].key?(:collection)
          _set_ref(args.first.split("/").last)
        end
      end
    end

    def merge!(object)
      hash_or_array = ::Jbuilder === object ? object.attributes! : object
      hash_or_array = _format_keys(hash_or_array)
      hash_or_array.deep_transform_values! { |value| _get_type(value) } if hash_or_array.is_a?(Hash)
      @attributes = _merge_values(@attributes, hash_or_array)
    end

    private

    def _set_ref(component)
      if @inline_array
        if @collection
          _set_value(:type, :array)
          _set_value(:items, { "$ref" => _component_path(component)})
        else
          _set_value("$ref", _component_path(component))
        end
      else
        @type = :array
        _set_value(:items, { "$ref" => _component_path(component)})
      end
    end

    def _component_path(component)
      "#/components/schemas/#{component}"
    end

    def _get_type(value)
      return value if _blank?(value)

      _schematize_type(value)
    end

    def _schematize_type(value)
      type = value.class.name.downcase.to_sym

      case type
      when :datetime, :"activesupport::timewithzone"
        { type: :string, format: "date-time" }
      when nil, :text, :nilclass
        { type: :string }
      when :float, :decimal
        { type: :number }
      when :array
        # TODO: Find a way to store same keys with different values in the same hash
        # { "type" => :array, contains: value.map { |v| _schematize_type(v).compare_by_identity }.inject(:merge), minContains: 0 }
        { type: :array, contains: value.map { |v| _schematize_type(v).compare_by_identity }.inject(:merge), minContains: 0 }
      else
        { type: type }
      end
    end

    ###
    # Jbuilder methods
    ###

    def _key(key)
      @key_formatter ? @key_formatter.format(key).to_sym : key.to_sym
    end

    def _extract_hash_values(object, attributes)
      attributes.each{ |key| _set_value key, _get_type(_format_keys(object.fetch(key))) }
    end

    def _extract_method_values(object, attributes)
      attributes.each{ |key| _set_value key, _get_type(_format_keys(object.public_send(key))) }
    end

    def _map_collection(collection)
      super.first
    end
  end
end
