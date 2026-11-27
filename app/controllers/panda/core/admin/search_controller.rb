# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SearchController < ::Panda::Core::Admin::BaseController
        def index
          query = params[:q].to_s.strip
          # `limit` defaults to the five a group shows in the palette. "Show all"
          # asks for one group (`group=People`) with a larger limit.
          limit = params.fetch(:limit, 5).to_i.clamp(1, 50)
          results = Panda::Core::SearchRegistry.admin_search(query, limit: limit, group: params[:group].presence)
          render json: results
        end
      end
    end
  end
end
