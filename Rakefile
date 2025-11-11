require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "bundler/gem_tasks"

# Load Panda Core rake tasks
Dir[File.expand_path("lib/tasks/*.rake", __dir__)].each { |f| load f }
