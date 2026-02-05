# frozen_string_literal: true

module Chikuden
  module Adapters
    module Pagy
      module Frontend
        # Override pagy_url_for to include cursor_id
        def pagy_url_for(pagy, page, absolute: false, html_escaped: false)
          cursor_id = pagy.respond_to?(:chikuden_cursor_id) ? pagy.chikuden_cursor_id : nil

          if cursor_id
            url = super
            cursor_param = Chikuden.config.cursor_param
            separator = url.include?("?") ? "&" : "?"
            url = "#{url}#{separator}#{cursor_param}=#{cursor_id}"
            html_escaped ? url.gsub("&", "&amp;") : url
          else
            super
          end
        end

        # Helper to get cursor_id from pagy instance
        def chikuden_cursor_id(pagy)
          pagy.respond_to?(:chikuden_cursor_id) ? pagy.chikuden_cursor_id : nil
        end

        # Hidden field for forms that need to preserve cursor_id
        def chikuden_cursor_field(pagy)
          cursor_id = chikuden_cursor_id(pagy)
          return unless cursor_id

          cursor_param = Chikuden.config.cursor_param
          hidden_field_tag(cursor_param, cursor_id)
        end
      end
    end
  end
end
