module JbuilderSchema
  module Helpers

    def jbuilder_schema(path)
      # {type: :array, items: {} } # if 'index'
      # { '$ref' => "#/components/schemas/#{path}" }

      {
        type: :object,
        properties: {
          id: { type: :integer },
          title: { type: :string },
          body: { type: :string },
          created_at: { type: :string, format: :"date-time" },
          updated_at: { type: :string, format: :"date-time" },
          url: { type: :string }
        },
        required: %w[id title body]
      }

      _object
    end

    def resolve
      _resolve
    end

    private

    def _object
      {
        type: :object,
        title: '',
        description: '',
        links: [],
        properties: {}
      }
    end

    def _register_handler
      ActionView::Template.register_template_handler(:jbuilder, JbuilderSchema::Handler)
    end

    def _resolve
      JbuilderSchema::Resolver.new.find_all('article', 'articles', true)
    end

  end
end