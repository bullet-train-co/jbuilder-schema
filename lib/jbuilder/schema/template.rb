require "jbuilder/jbuilder_template"
require "jbuilder/blank"

module JbuilderSchema
  class Template < ::JbuilderTemplate
    class << self
      attr_accessor :template_lookup_options
    end

    self.template_lookup_options = {handlers: [:jbuilder]}

    @@key_formatter = nil
    @@ignore_nil = false
    @@deep_format_keys = false
    BLANK = Blank.new

    def initialize(options = {})
      @context = nil
      @cached_root = nil

      @attributes = {}

      @key_formatter = options.fetch(:key_formatter) { @@key_formatter ? @@key_formatter.clone : nil }
      @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)
      @deep_format_keys = options.fetch(:deep_format_keys, @@deep_format_keys)

      yield self if ::Kernel.block_given?
    end

    def schema!
      @attributes
    end

    def set!(key, value = BLANK, *args, &block)
      result = if block
        if !_blank?(value)
          # json.comments @post.comments { |comment| ... }
          # { "comments": [ { ... }, { ... } ] }
          _scope { array! value, &block }
        else
          # json.comments { ... }
          # { "comments": ... }
          _merge_block(key) { yield self }
        end
      elsif args.empty?
        if ::Jbuilder === value
          # json.age 32
          # json.person another_jbuilder
          # { "age": 32, "person": { ...  }
          _format_keys(value.attributes!)
        else
          # json.age 32
          # { "age": 32 }
          type = _get_type(value)
          _format_keys(type)
        end
      elsif _is_collection?(value)
        # json.comments @post.comments, :content, :created_at
        # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
        _scope { array! value, *args }
      else
        # json.author @post.creator, :name, :email_address
        # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
        _merge_block(key) { extract! value, *args }
      end

      _set_value key.to_sym, result
    end

    def method_missing(*args, &block)
      # puts ">>>HELLO MF!!!"
      # puts ">>>method_missing ARGS>> #{args}"

      # Get object and type:
      # ObjectSpace.each_object(Class).select { |c| c.name == '@article'.gsub('@', '').classify }.first.columns_hash["id"].type
      if block
        set!(*args, &block)
      else
        set!(*args)
      end
    end

    private

    # def _render_partial(options)
    #   puts ">>>PARTIAL: #{options[:partial]}"
    #   puts ">>>OPTIONS: #{options}"
    #   puts ">>>SELF: #{self}"
    #   options[:locals].merge! json: self
    #   @context.render options
    # end

    def _get_type(value)
      return value if _blank?(value)

      {type: value.class.name.downcase.to_sym}
    end

    def _key(key)
      @key_formatter ? @key_formatter.format(key).to_sym : key.to_sym
    end
  end
end
