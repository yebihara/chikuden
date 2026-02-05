# frozen_string_literal: true

require "bundler/setup"
require "active_support"
require "active_support/current_attributes"
require "chikuden"

# Use memory store for testing
Chikuden.store = Chikuden::Store::Memory.new

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Chikuden.store.clear if Chikuden.store.respond_to?(:clear)
    Chikuden::Current.reset
  end
end
