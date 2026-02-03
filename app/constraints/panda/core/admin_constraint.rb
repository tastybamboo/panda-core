# frozen_string_literal: true

module Panda
  module Core
    class AdminConstraint
      def matches?(request)
        return false unless request.session[Panda::Core::ADMIN_SESSION_KEY].present?

        user = User.find_by(id: request.session[Panda::Core::ADMIN_SESSION_KEY])
        user&.admin?
      end
    end
  end
end
