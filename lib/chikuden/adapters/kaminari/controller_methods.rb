# frozen_string_literal: true

module Chikuden
  module Adapters
    module Kaminari
      module ControllerMethods
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Enable Chikuden for specific actions
          # @param enabled [Boolean] whether to enable chikuden
          # @param options [Hash] options passed to before_action (:only, :except)
          def chikuden(enabled = true, **options)
            before_action(**options.slice(:only, :except)) do
              cursor_param = Chikuden.config.cursor_param
              Chikuden::Current.enabled = enabled
              Chikuden::Current.cursor_id = params[cursor_param]
              Chikuden::Current.page = params[:page]
            end
          end
        end
      end
    end
  end
end
