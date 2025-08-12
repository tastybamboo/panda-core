# frozen_string_literal: true

namespace :panda do
  namespace :core do
    namespace :install do
      desc "Copy migrations from panda_core to application"
      task :migrations do
        # Delegate to the auto-generated task
        Rake::Task["panda_core:install:migrations"].invoke
      end
    end
  end
end
