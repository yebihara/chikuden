# frozen_string_literal: true

module Chikuden
  class Configuration
    attr_accessor :redis, :ttl, :max_ids, :cursor_param, :logger

    def initialize
      @redis = nil
      @ttl = 30 * 60 # 30 minutes in seconds
      @max_ids = 100_000
      @cursor_param = :cursor_id
      @logger = nil
    end

    def redis!
      raise ConfigurationError, "Redis is not configured. Please set Chikuden.config.redis" unless @redis
      @redis
    end

    def logger
      @logger ||= default_logger
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      end
    end
  end
end
