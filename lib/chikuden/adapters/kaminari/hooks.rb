# frozen_string_literal: true

module Chikuden
  module Adapters
    module Kaminari
      class << self
        def wrap_page_method(klass)
          return unless klass.respond_to?(:page)
          return if klass.singleton_class.method_defined?(:page_without_chikuden)

          klass.singleton_class.class_eval do
            alias_method :page_without_chikuden, :page

            define_method(:page) do |num = nil|
              result = page_without_chikuden(num)
              if Chikuden::Current.enabled
                result.chikuden_enabled = true
              end
              result
            end
          end
        end
      end
    end
  end
end
