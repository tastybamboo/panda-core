# frozen_string_literal: true

# Simple controller for ViewComponent testing
class ViewComponentTestController < ActionController::Base
  # Disable CSRF protection for test controller
  # This is intentional as this controller is only used for component testing
  protect_from_forgery with: :null_session

  # Include necessary helpers
  include Rails.application.routes.url_helpers if defined?(Rails.application)

  # Set up a basic layout
  layout false

  # Make helpers available
  def helpers
    ActionController::Base.helpers
  end
end
