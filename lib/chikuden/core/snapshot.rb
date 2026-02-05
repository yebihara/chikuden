# frozen_string_literal: true

module Chikuden
  module Core
    class Snapshot
      attr_reader :cursor

      def initialize(cursor, store: nil)
        @cursor = cursor
        @store = store || Chikuden.store
      end

      # Get IDs for a specific page
      # @param page [Integer] page number (1-based)
      # @param per_page [Integer] items per page
      # @param offset [Integer] optional direct offset (overrides page calculation)
      # @return [Array<Integer>]
      def page_ids(page:, per_page:, offset: nil)
        offset ||= (page - 1) * per_page
        @store.fetch_page(@cursor.id, offset: offset, limit: per_page)
      end

      # Get total count
      # @return [Integer]
      def total_count
        @store.total_count(@cursor.id)
      end

      # Calculate total pages
      # @param per_page [Integer] items per page
      # @return [Integer]
      def total_pages(per_page:)
        (total_count.to_f / per_page).ceil
      end

      # Check if there's a next page
      # @param page [Integer] current page number (1-based)
      # @param per_page [Integer] items per page
      # @return [Boolean]
      def next_page?(page:, per_page:)
        page < total_pages(per_page: per_page)
      end

      # Check if there's a previous page
      # @param page [Integer] current page number (1-based)
      # @return [Boolean]
      def prev_page?(page:)
        page > 1
      end

      # Cursor ID accessor
      # @return [String]
      def cursor_id
        @cursor.id
      end
    end
  end
end
