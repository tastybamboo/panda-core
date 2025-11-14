# frozen_string_literal: true

require "pathname"
require "panda/assets/runner"

namespace :panda do
  namespace :core do
    namespace :assets do
      # Resolve spec/dummy from either engine root or dummy itself
      def dummy_root
        root = Rails.root
        return root if root.basename.to_s == "dummy"

        candidate = root.join("spec/dummy")
        return candidate if candidate.exist?

        raise "❌ Cannot find dummy root – expected #{candidate}"
      end

      def engine_root
        Panda::Core::Engine.root
      end

      def engine_js_roots
        roots = []
        app_js = engine_root.join("app/javascript/panda/core")
        vendor_js = engine_root.join("vendor/javascript/panda/core")

        roots << app_js if app_js.directory?
        roots << vendor_js if vendor_js.directory?

        roots
      end

      desc "Prepare Panda Core dummy assets (compile + importmap + copy JS)"
      task prepare_dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/core"
        }

        result = Panda::Assets::Runner.prepare(:core, config)
        abort("❌ Panda Core dummy prepare failed") unless result.ok
      end

      desc "Verify Panda Core dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/core"
        }

        result = Panda::Assets::Runner.verify(:core, config)
        abort("❌ Panda Core dummy verify failed") unless result.ok
      end

      desc "Full Panda Core dummy asset pipeline (prepare + verify)"
      task dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/core"
        }

        result = Panda::Assets::Runner.run(:core, config)
        abort("❌ Panda Core dummy pipeline failed") unless result.ok
      end

      # Convenience alias if you like “prepare_and_verify_dummy” wording
      desc "Prepare + verify Panda Core assets (alias for :dummy)"
      task prepare_and_verify_dummy: :dummy
    end
  end
end
