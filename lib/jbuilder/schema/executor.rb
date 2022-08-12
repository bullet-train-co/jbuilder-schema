# frozen_string_literal: true

module JbuilderSchema
  class Executor

    def initialize(locals)
      locals.each { |k, v| define_singleton_method(k) {v } }
    end

    def exec(proc)
      instance_exec &proc
    end

    def included(base)
      @parent = base
    end

    def method_missing method, *args
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        ::Rails.application.routes.url_helpers.send(method, *args, only_path: true)
      else
        super
      end
    end
  end
end