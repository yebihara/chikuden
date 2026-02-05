# frozen_string_literal: true

module Chikuden
  module Store
    class Redis < Base
      PREFIX = "chikuden"
      IDS_SUFFIX = "ids"
      META_SUFFIX = "meta"

      def initialize(redis: nil, ttl: nil, max_ids: nil)
        @redis = redis
        @ttl = ttl
        @max_ids = max_ids
      end

      def store(cursor_id, ids, total_count:)
        ids_key = ids_key(cursor_id)
        meta_key = meta_key(cursor_id)
        ttl = effective_ttl
        max_ids = effective_max_ids

        # Truncate IDs if exceeding max
        stored_ids = ids.take(max_ids)

        log(:info) do
          "[Chikuden] STORE cursor_id=#{cursor_id} ids_count=#{stored_ids.size} total_count=#{total_count} ttl=#{ttl}s"
        end

        redis.multi do |multi|
          # Clear existing data
          multi.del(ids_key, meta_key)

          # Store IDs in sorted set with index as score
          if stored_ids.any?
            members = stored_ids.each_with_index.map { |id, index| [index, id] }
            multi.zadd(ids_key, members)
          end

          # Store metadata
          multi.hset(meta_key, "total_count", total_count)
          multi.hset(meta_key, "stored_count", stored_ids.size)

          # Set TTL
          multi.expire(ids_key, ttl)
          multi.expire(meta_key, ttl)
        end

        log(:info) { "[Chikuden] ZADD #{ids_key} (#{stored_ids.size} members)" }

        true
      end

      def fetch_page(cursor_id, offset:, limit:)
        ids_key = ids_key(cursor_id)

        raise CursorExpired, "Cursor '#{cursor_id}' has expired" unless exists?(cursor_id)

        # ZRANGE with BYSCORE to get IDs by index range
        # Score is the index, so we use ZRANGE start end
        start_index = offset
        end_index = offset + limit - 1

        log(:info) do
          "[Chikuden] ZRANGE #{ids_key} #{start_index} #{end_index}"
        end

        result = redis.zrange(ids_key, start_index, end_index)

        log(:info) do
          "[Chikuden] FETCH cursor_id=#{cursor_id} offset=#{offset} limit=#{limit} fetched=#{result.size}"
        end

        result.map(&:to_i)
      end

      def total_count(cursor_id)
        meta_key = meta_key(cursor_id)
        count = redis.hget(meta_key, "total_count")

        raise CursorExpired, "Cursor '#{cursor_id}' has expired" if count.nil?

        log(:info) { "[Chikuden] HGET #{meta_key} total_count=#{count}" }

        count.to_i
      end

      def stored_count(cursor_id)
        meta_key = meta_key(cursor_id)
        count = redis.hget(meta_key, "stored_count")

        raise CursorExpired, "Cursor '#{cursor_id}' has expired" if count.nil?

        count.to_i
      end

      def exists?(cursor_id)
        result = redis.exists?(meta_key(cursor_id))
        log(:info) { "[Chikuden] EXISTS cursor_id=#{cursor_id} result=#{result}" }
        result
      end

      def delete(cursor_id)
        log(:info) { "[Chikuden] DEL cursor_id=#{cursor_id}" }
        redis.del(ids_key(cursor_id), meta_key(cursor_id)) > 0
      end

      def touch(cursor_id)
        ttl = effective_ttl
        ids_key = ids_key(cursor_id)
        meta_key = meta_key(cursor_id)

        return false unless exists?(cursor_id)

        log(:info) { "[Chikuden] TOUCH cursor_id=#{cursor_id} ttl=#{ttl}s" }

        redis.multi do |multi|
          multi.expire(ids_key, ttl)
          multi.expire(meta_key, ttl)
        end

        true
      end

      def remove_ids(cursor_id, ids)
        return 0 if ids.empty?

        ids_key = ids_key(cursor_id)

        log(:info) { "[Chikuden] ZREM cursor_id=#{cursor_id} ids=#{ids.inspect}" }

        removed = redis.zrem(ids_key, ids)
        removed.is_a?(Integer) ? removed : (removed ? ids.size : 0)
      end

      def decrement_total_count(cursor_id, count)
        meta_key = meta_key(cursor_id)

        new_count = redis.hincrby(meta_key, "total_count", -count)
        redis.hincrby(meta_key, "stored_count", -count)

        log(:info) { "[Chikuden] DECR_COUNT cursor_id=#{cursor_id} by=#{count} new_total=#{new_count}" }

        new_count
      end

      private

      def redis
        @redis || Chikuden.config.redis!
      end

      def effective_ttl
        @ttl || Chikuden.config.ttl
      end

      def effective_max_ids
        @max_ids || Chikuden.config.max_ids
      end

      def ids_key(cursor_id)
        "#{PREFIX}:#{cursor_id}:#{IDS_SUFFIX}"
      end

      def meta_key(cursor_id)
        "#{PREFIX}:#{cursor_id}:#{META_SUFFIX}"
      end

      def log(level, &block)
        logger = Chikuden.config.logger
        return unless logger

        logger.public_send(level, &block)
      end
    end
  end
end
