# frozen_string_literal: true

module Panda
  module Core
    class AdminConstraint
      def matches?(request)
        return false unless request.session[:user_id].present?

        user = User.find_by(id: request.session[:user_id])
        user&.is_admin?
      end
    end
  end
end
