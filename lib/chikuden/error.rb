# frozen_string_literal: true

module Chikuden
  class Error < StandardError; end
  class CursorNotFound < Error; end
  class CursorExpired < Error; end
  class ConfigurationError < Error; end
end
