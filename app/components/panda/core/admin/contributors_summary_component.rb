# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContributorsSummaryComponent < Panda::Core::Base
        def initialize(contributors:, total_count:, last_updated_at:, count_label: "version", heading: "Contributors", **attrs)
          @contributors = contributors
          @total_count = total_count
          @count_label = count_label
          @last_updated_at = last_updated_at
          @heading = heading
          super(**attrs)
        end

        attr_reader :contributors, :total_count, :count_label, :last_updated_at, :heading

        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::DateHelper
      end
    end
  end
end
