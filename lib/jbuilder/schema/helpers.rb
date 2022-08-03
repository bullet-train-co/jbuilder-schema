require "jbuilder/schema/resolver"

module JbuilderSchema
  module Helpers
    def jbuilder_schema(path)
      # {type: :array, items: {} } # if 'index'
      # { '$ref' => "#/components/schemas/#{path}" }

      # {
      #   type: :object,
      #   properties: {
      #     id: { type: :integer },
      #     title: { type: :string },
      #     body: { type: :string },
      #     created_at: { type: :string, format: :"date-time" },
      #     updated_at: { type: :string, format: :"date-time" },
      #     url: { type: :string }
      #   },
      #   required: %w[id title body]
      # }

      @template ||= _resolve(path)
      return {} unless @template

      _set_properties @template.schema!
      #
      # puts ">>>OBJ #{_object}"

      _object

      # {:type=>:object, :title=>"", :description=>"", :links=>[], :properties=>{:id=>{:type=>:integer}, :title=>{:type=>:string}}}
    end

    private

    def _object
      @object ||= {
        type: :object,
        title: "",
        description: "",
        links: [],
        properties: {}
      }
    end

    def _set_properties(schema)
      _object[:properties].merge! schema
    end

    def _resolve(path)
      prefix, controller, action, partial = _resolve_path(path)
      JbuilderSchema::Resolver.new(prefix).find_all(action, controller, partial)
    end

    def _resolve_path(path)
      action = path.split("/").last
      controller = path.split("/")[-2]
      prefix = path.delete_suffix("/#{controller}/#{action}")
      partial = action[0] == "_"

      [prefix, controller, action, partial]
    end
  end
end
