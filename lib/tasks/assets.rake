# panda/core/lib/tasks/assets.rake

# frozen_string_literal: true

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Run shared dummy asset prepare + verify pipeline (Core)"
      task :prepare_and_verify_dummy do
        require "panda/core/testing/assets/runner"

        Panda::Core::Testing::Assets.run!(
          engine_label: "Panda Core",
          engine_root: Panda::Core::Engine.root,
          engine_js_subpath: "panda/core",
          dummy_root: Panda::Core::Testing::Assets.find_dummy_root,
          rails_env: ENV.fetch("RAILS_ENV", "test")
        )
      end
    end
  end
end
