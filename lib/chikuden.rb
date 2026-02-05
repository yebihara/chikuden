# frozen_string_literal: true

require "chikuden/version"
require "chikuden/error"
require "chikuden/configuration"
require "chikuden/current"

# Store
require "chikuden/store/base"
require "chikuden/store/redis"
require "chikuden/store/memory"

# Core
require "chikuden/core/cursor"
require "chikuden/core/snapshot"
require "chikuden/core/page_fetcher"

# Railtie (loads adapters conditionally)
require "chikuden/railtie" if defined?(Rails)

module Chikuden
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    # Default store instance
    def store
      @store ||= Store::Redis.new
    end

    # Allow setting a custom store (useful for testing)
    def store=(store)
      @store = store
    end

    # Reset store (useful for testing)
    def reset_store!
      @store = nil
    end
  end
end
