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
  #    json.title human_title(@article)
  #
  # ✅ Relations:
  #    json.user_name @article.user.name
  #    json.comments @article.comments, :content, :created_at
  #
  # ⛔ Collections:
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
  class Template < ::JbuilderTemplate
    def initialize(context, *args)
      @type = :object
      @inline_array = false
      @collection = false
      super
    end

    def set!(key, value = BLANK, *args, &block)
      result = if ::Kernel.block_given?
                 if !_blank?(value)
                   # json.comments @post.comments { |comment| ... }
                   # { "comments": [ { ... }, { ... } ] }
                   puts ">>> PARTIAL ARRAY"
                   _scope{ array! value, &block }
                 else
                   # json.comments { ... }
                   # { "comments": ... }
                   puts ">>> BLOCK"
                   @inline_array = true
                   _merge_block(key){ yield self }
                 end
               elsif args.empty?
                 if ::Jbuilder === value
                   # json.age 32
                   # json.person another_jbuilder
                   # { "age": 32, "person": { ...  }
                   puts ">>> ATTRIBUTE1"
                   _format_keys(value.attributes!)
                 else
                   # json.age 32
                   # { "age": 32 }
                   puts ">>> ATTRIBUTE2"
                   _format_keys(_get_type(value))
                 end
               elsif _is_collection?(value)
                 puts ">>> COLLECTION"
                 @inline_array = true
                 @collection = true
                 # json.comments @post.comments, :content, :created_at
                 # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
                 _scope{ array! value, *args }
               else
                 puts ">>> ELSE"
                 # json.author @post.creator, :name, :email_address
                 # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
                 _merge_block(key){ extract! value, *args }
               end

      _set_value key, result
    end

    def properties
      @attributes
    end

    def object_type
      @type
    end

    def array!(collection = [], *args)
      options = args.first

      if args.one? && _partial_options?(options)
        # @type = :array
        # @attributes["$ref"] = "#/components/schemas/#{options[:partial].split("/").last}"
        _set_ref(options[:partial].split("/").last)
      else
        super
      end
    end

    def partial!(*args)
      # partial = args.first
      # _set_value

      # puts ">>> partial! mcaller: #{caller}"
      puts ">>> partial! method called with args: #{args}"

      # puts ">>>ARGS #{ args.first[:partial].split('/').last }"
      if args.one? && _is_active_model?(args.first)
      puts ">>>1"
      #   _render_active_model_partial args.first
      else
        if args.first.is_a?(Hash)
          _set_ref(args.first[:partial].split("/").last)
        else
          @collection = true if args[1].key?(:collection)
          _set_ref(args.first.split("/").last)
        end

      # { type: :array, "$ref" => "#/components/schemas/#{args.first[:partial].split("/").last}" }
        # _render_explicit_partial(*args)
      end
    end

    private

    def _set_ref(component)
      if @inline_array
        @collection ? _set_value(:type, :array) : _set_value(:type, :object)
      else
        @type = :array
      end

      _set_value(:items, { "$ref" => "#/components/schemas/#{component}"})
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
      when nil, :text
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
  end
end
