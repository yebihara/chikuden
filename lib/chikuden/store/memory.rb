# frozen_string_literal: true

module Chikuden
  module Store
    # In-memory store for testing purposes
    # Not thread-safe, not suitable for production use
    class Memory < Base
      def initialize(ttl: nil, max_ids: nil)
        @data = {}
        @ttl = ttl
        @max_ids = max_ids
      end

      def store(cursor_id, ids, total_count:)
        max_ids = effective_max_ids
        stored_ids = ids.take(max_ids)
        ttl = effective_ttl

        log(:info) do
          "[Chikuden::Memory] STORE cursor_id=#{cursor_id} ids_count=#{stored_ids.size} total_count=#{total_count} ttl=#{ttl}s"
        end

        @data[cursor_id] = {
          ids: stored_ids,
          total_count: total_count,
          stored_count: stored_ids.size,
          expires_at: Time.now + ttl
        }

        true
      end

      def fetch_page(cursor_id, offset:, limit:)
        cleanup_expired

        data = @data[cursor_id]
        raise CursorExpired, "Cursor '#{cursor_id}' has expired" if data.nil?

        result = data[:ids][offset, limit] || []

        log(:info) do
          "[Chikuden::Memory] FETCH cursor_id=#{cursor_id} offset=#{offset} limit=#{limit} fetched=#{result.size}"
        end

        result
      end

      def total_count(cursor_id)
        cleanup_expired

        data = @data[cursor_id]
        raise CursorExpired, "Cursor '#{cursor_id}' has expired" if data.nil?

        log(:info) { "[Chikuden::Memory] TOTAL_COUNT cursor_id=#{cursor_id} count=#{data[:total_count]}" }

        data[:total_count]
      end

      def stored_count(cursor_id)
        cleanup_expired

        data = @data[cursor_id]
        raise CursorExpired, "Cursor '#{cursor_id}' has expired" if data.nil?

        data[:stored_count]
      end

      def exists?(cursor_id)
        cleanup_expired

        result = @data.key?(cursor_id)
        log(:info) { "[Chikuden::Memory] EXISTS cursor_id=#{cursor_id} result=#{result}" }
        result
      end

      def delete(cursor_id)
        log(:info) { "[Chikuden::Memory] DEL cursor_id=#{cursor_id}" }
        !!@data.delete(cursor_id)
      end

      def touch(cursor_id)
        return false unless @data.key?(cursor_id)

        ttl = effective_ttl
        log(:info) { "[Chikuden::Memory] TOUCH cursor_id=#{cursor_id} ttl=#{ttl}s" }

        @data[cursor_id][:expires_at] = Time.now + ttl
        true
      end

      def remove_ids(cursor_id, ids)
        return 0 if ids.empty?

        data = @data[cursor_id]
        return 0 if data.nil?

        log(:info) { "[Chikuden::Memory] REMOVE_IDS cursor_id=#{cursor_id} ids=#{ids.inspect}" }

        original_size = data[:ids].size
        data[:ids] = data[:ids] - ids
        removed = original_size - data[:ids].size
        data[:stored_count] = data[:ids].size

        removed
      end

      def decrement_total_count(cursor_id, count)
        data = @data[cursor_id]
        return 0 if data.nil?

        data[:total_count] -= count
        log(:info) { "[Chikuden::Memory] DECR_COUNT cursor_id=#{cursor_id} by=#{count} new_total=#{data[:total_count]}" }

        data[:total_count]
      end

      # Test helper: clear all data
      def clear
        @data.clear
      end

      # Test helper: get raw data
      def raw_data
        @data
      end

      private

      def effective_ttl
        @ttl || Chikuden.config.ttl
      end

      def effective_max_ids
        @max_ids || Chikuden.config.max_ids
      end

      def cleanup_expired
        now = Time.now
        @data.delete_if { |_, v| v[:expires_at] < now }
      end

      def log(level, &block)
        logger = Chikuden.config.logger
        return unless logger

        logger.public_send(level, &block)
      end
    end
  end
end
