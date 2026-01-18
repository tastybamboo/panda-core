# frozen_string_literal: true

# Simple controller for ViewComponent testing
class ViewComponentTestController < ActionController::Base
  # Include necessary helpers
  include Rails.application.routes.url_helpers if defined?(Rails.application)

  # Set up a basic layout
  layout false

  # Make helpers available
  def helpers
    ActionController::Base.helpers
  end
end
