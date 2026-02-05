# frozen_string_literal: true

module Chikuden
  class Railtie < Rails::Railtie
    initializer "chikuden.setup" do
      # Load Kaminari adapter if Kaminari is available
      ActiveSupport.on_load(:action_controller) do
        if defined?(::Kaminari)
          require "chikuden/adapters/kaminari/controller_methods"
          include Chikuden::Adapters::Kaminari::ControllerMethods
        end

        if defined?(::Pagy)
          require "chikuden/adapters/pagy/backend"
          include Chikuden::Adapters::Pagy::Backend
        end
      end

      ActiveSupport.on_load(:active_record) do
        if defined?(::Kaminari)
          require "chikuden/adapters/kaminari/relation_extension"
          ActiveRecord::Relation.prepend Chikuden::Adapters::Kaminari::RelationExtension
        end
      end

      ActiveSupport.on_load(:action_view) do
        if defined?(::Kaminari)
          require "chikuden/adapters/kaminari/view_helpers"
          prepend Chikuden::Adapters::Kaminari::ViewHelpers
        end

        if defined?(::Pagy)
          require "chikuden/adapters/pagy/frontend"
          prepend Chikuden::Adapters::Pagy::Frontend
        end
      end
    end

    config.to_prepare do
      if defined?(::Kaminari) && defined?(ApplicationRecord)
        require "chikuden/adapters/kaminari/hooks"
        Chikuden::Adapters::Kaminari.wrap_page_method(ApplicationRecord)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?
          next unless model.respond_to?(:page)

          Chikuden::Adapters::Kaminari.wrap_page_method(model)
        end
      end
    end
  end
end
