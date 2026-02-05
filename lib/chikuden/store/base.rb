# frozen_string_literal: true

module Chikuden
  module Store
    class Base
      # Store IDs with a cursor_id
      # @param cursor_id [String] unique cursor identifier
      # @param ids [Array<Integer>] array of record IDs in order
      # @param total_count [Integer] total number of records
      # @return [Boolean] success status
      def store(cursor_id, ids, total_count:)
        raise NotImplementedError
      end

      # Fetch a page of IDs
      # @param cursor_id [String] unique cursor identifier
      # @param offset [Integer] starting position (0-based)
      # @param limit [Integer] number of IDs to fetch
      # @return [Array<Integer>] array of record IDs
      def fetch_page(cursor_id, offset:, limit:)
        raise NotImplementedError
      end

      # Get total count for a cursor
      # @param cursor_id [String] unique cursor identifier
      # @return [Integer] total count
      def total_count(cursor_id)
        raise NotImplementedError
      end

      # Check if cursor exists
      # @param cursor_id [String] unique cursor identifier
      # @return [Boolean]
      def exists?(cursor_id)
        raise NotImplementedError
      end

      # Delete a cursor
      # @param cursor_id [String] unique cursor identifier
      # @return [Boolean] success status
      def delete(cursor_id)
        raise NotImplementedError
      end

      # Refresh TTL for a cursor
      # @param cursor_id [String] unique cursor identifier
      # @return [Boolean] success status
      def touch(cursor_id)
        raise NotImplementedError
      end

      # Remove specific IDs from the cursor (for deleted records)
      # @param cursor_id [String] unique cursor identifier
      # @param ids [Array<Integer>] IDs to remove
      # @return [Integer] number of IDs removed
      def remove_ids(cursor_id, ids)
        raise NotImplementedError
      end

      # Decrement total count
      # @param cursor_id [String] unique cursor identifier
      # @param count [Integer] amount to decrement
      # @return [Integer] new total count
      def decrement_total_count(cursor_id, count)
        raise NotImplementedError
      end
    end
  end
end
