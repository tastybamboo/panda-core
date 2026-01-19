# frozen_string_literal: true

# The base controller that all other controllers inherit from.
# Provides common functionality and configuration.
#
# @abstract Subclass and use as a base controller
class ApplicationController < ActionController::Base
  # Disable CSRF protection in test environment for component tests
  protect_from_forgery with: :null_session if Rails.env.test?
end
