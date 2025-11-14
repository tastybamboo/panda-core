# frozen_string_literal: true

require "erb"
require "fileutils"

module Panda
  module Assets
    class HTMLReport
      TEMPLATE = File.expand_path("report.html.erb", __dir__)

      def self.write!(summary)
        renderer = ERB.new(File.read(TEMPLATE))
        html = renderer.result(binding)

        output = Rails.root.join("spec/dummy/tmp/panda_assets_report.html")
        FileUtils.mkdir_p(output.dirname)
        File.write(output, html)

        output
      end
    end
  end
end
