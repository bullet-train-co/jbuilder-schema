# frozen_string_literal: true

require 'jbuilder/jbuilder_template'
require 'active_support/inflections'
require 'safe_parser'

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
    def set!(key, value = BLANK, *args, &block)
      result = if ::Kernel.block_given?
                 if !_blank?(value)
                   # json.comments @post.comments { |comment| ... }
                   # { "comments": [ { ... }, { ... } ] }
                   _scope{ array! value, &block }
                 else
                   # json.comments { ... }
                   # { "comments": ... }
                   _merge_block(key){ yield self }
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
                   # _format_keys(value)
                   type = _get_type(value)
                   _format_keys(type)
                 end
               elsif _is_collection?(value)
                 # json.comments @post.comments, :content, :created_at
                 # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
                 _scope{ array! value, *args }
               else
                 # json.author @post.creator, :name, :email_address
                 # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
                 _merge_block(key){ extract! value, *args }
               end

      _set_value key, result
    end

    def properties
      @attributes
    end

    private

    def _get_type(value)
      return value if _blank?(value)

      _schematize_type(value.class.name.downcase.to_sym)
    end

    def _schematize_type(type)
      case type
      when :datetime, :"activesupport::timewithzone"
        { type: :string, format: 'date-time' }
      when nil, :text
        { type: :string }
      when :float, :decimal
        { type: :number }
      else
        { type: type }
      end
    end

    def _create_properties!
      sorted_hash = _parse_lines!.sort.to_h

      {}.tap do |hash|
        sorted_hash.each do |_index, line|
          hash[line[:property]] = line[:schema]
        end
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
