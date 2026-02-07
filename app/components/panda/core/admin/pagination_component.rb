# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class PaginationComponent < Panda::Core::Base
        def initialize(page:, total_pages:, total_count:, per_page:, item_name: "items", **attrs)
          @page = page
          @total_pages = total_pages
          @total_count = total_count
          @per_page = per_page
          @item_name = item_name
          super(**attrs)
        end

        attr_reader :page, :total_pages, :total_count, :per_page, :item_name

        def render?
          total_pages > 1
        end

        def first_item
          ((page - 1) * per_page) + 1
        end

        def last_item
          [page * per_page, total_count].min
        end

        def previous_page?
          page > 1
        end

        def next_page?
          page < total_pages
        end

        def show_page?(page_num)
          page_num == page ||
            (page_num - page).abs <= 2 ||
            page_num == 1 ||
            page_num == total_pages
        end

        def show_ellipsis?(page_num)
          (page_num - page).abs == 3
        end

        def page_url(page_num)
          query = helpers.request.query_parameters.merge("page" => page_num)
          "#{helpers.request.path}?#{query.to_query}"
        end
      end
    end
  end
end
