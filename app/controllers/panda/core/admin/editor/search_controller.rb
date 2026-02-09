# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module Editor
        class SearchController < ::Panda::Core::Admin::BaseController
          def index
            query = params[:search].to_s.strip
            items = Panda::Core::SearchRegistry.search(query, limit: 10)
            render json: {success: true, items: items}
          end
        end
      end
    end
  end
end
