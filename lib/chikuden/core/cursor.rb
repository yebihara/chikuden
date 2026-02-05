# frozen_string_literal: true

require "securerandom"

module Chikuden
  module Core
    class Cursor
      attr_reader :id

      def initialize(id)
        @id = id
      end

      class << self
        # Create a new cursor and store IDs
        # @param ids [Array<Integer>] array of record IDs in order
        # @param total_count [Integer] total number of records (may be larger than ids.size)
        # @param store [Chikuden::Store::Base] storage backend
        # @return [Cursor]
        def create(ids, total_count: nil, store: nil)
          store ||= default_store
          total_count ||= ids.size
          cursor_id = generate_id

          store.store(cursor_id, ids, total_count: total_count)

          new(cursor_id)
        end

        # Find an existing cursor
        # @param cursor_id [String] cursor identifier
        # @param store [Chikuden::Store::Base] storage backend
        # @return [Cursor, nil]
        def find(cursor_id, store: nil)
          return nil if cursor_id.nil? || cursor_id.empty?

          store ||= default_store
          return nil unless store.exists?(cursor_id)

          new(cursor_id)
        end

        # Find an existing cursor or raise
        # @param cursor_id [String] cursor identifier
        # @param store [Chikuden::Store::Base] storage backend
        # @return [Cursor]
        # @raise [CursorExpired]
        def find!(cursor_id, store: nil)
          cursor = find(cursor_id, store: store)
          raise CursorExpired, "Cursor '#{cursor_id}' has expired" if cursor.nil?

          cursor
        end

        private

        def generate_id
          SecureRandom.urlsafe_base64(16)
        end

        def default_store
          Chikuden.store
        end
      end

      def exists?(store: nil)
        store ||= Chikuden.store
        store.exists?(@id)
      end

      def total_count(store: nil)
        store ||= Chikuden.store
        store.total_count(@id)
      end

      def delete(store: nil)
        store ||= Chikuden.store
        store.delete(@id)
      end

      def touch(store: nil)
        store ||= Chikuden.store
        store.touch(@id)
      end
    end
  end
end
