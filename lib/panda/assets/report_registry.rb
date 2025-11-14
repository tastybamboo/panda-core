# frozen_string_literal: true

module Panda
  module Core
    module Assets
      module ReportRegistry
        extend self

        # Store path to last HTML report in-memory
        @last_report_path = nil

        def register(path)
          @last_report_path = path.to_s
        end

        def last
          @last_report_path
        end

        def present?
          @last_report_path && File.exist?(@last_report_path)
        end
      end
    end
  end
end
