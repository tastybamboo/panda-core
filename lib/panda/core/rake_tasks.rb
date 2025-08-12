# frozen_string_literal: true

module Panda
  module Core
    module RakeTasks
      def self.install_tasks
        Dir[File.expand_path("../tasks/*.rake", __dir__)].each { |f| load f }
      end
    end
  end
end

# Load tasks if Rake is available
if defined?(Rake)
  Panda::Core::RakeTasks.install_tasks
end
