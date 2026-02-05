# frozen_string_literal: true

# Pagy extra pattern for Chikuden integration
# Usage: require 'chikuden/adapters/pagy/extra'

require "chikuden/adapters/pagy/backend"
require "chikuden/adapters/pagy/frontend"

module Pagy
  # Add chikuden to Pagy's DEFAULT hash if not already present
  DEFAULT[:chikuden] ||= false
end

# Include backend in controllers
if defined?(ActionController::Base)
  ActionController::Base.include(Chikuden::Adapters::Pagy::Backend)
end

if defined?(ActionController::API)
  ActionController::API.include(Chikuden::Adapters::Pagy::Backend)
end

# Include frontend in views
if defined?(ActionView::Base)
  ActionView::Base.prepend(Chikuden::Adapters::Pagy::Frontend)
end
