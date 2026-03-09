# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SearchController < ::Panda::Core::Admin::BaseController
        def index
          query = params[:q].to_s.strip
          results = Panda::Core::SearchRegistry.admin_search(query, limit: 5)
          render json: results
        end
      end
    end
  end
end
