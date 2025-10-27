# frozen_string_literal: true

# Provide consistent namespacing for Panda tasks
# Rails auto-generates panda_core:* tasks from the module name,
# but we want to use panda:core:* for consistency across all Panda gems

namespace :panda do
  namespace :core do
    namespace :install do
      desc "Copy migrations from panda-core to application"
      task :migrations do
        Rake::Task["panda_core:install:migrations"].invoke
      end
    end
  end
end
