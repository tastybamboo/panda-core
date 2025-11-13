# frozen_string_literal: true

require "pathname"
require_relative "report"
require_relative "preparer"
require_relative "verifier"

module Panda
  module Core
    module Testing
      module Assets
        Config = Struct.new(
          :engine_label,
          :engine_root,
          :engine_js_subpath,
          :dummy_root,
          :rails_env,
          keyword_init: true
        )

        module_function

        # Shared helper – find spec/dummy regardless of current working directory
        def find_dummy_root
          root = Rails.root
          return root if root.basename.to_s == "dummy"

          candidate = root.join("spec/dummy")
          return candidate if candidate.exist?

          raise "❌ Cannot find dummy root – expected #{candidate}"
        end

        # Entry point – shared runner used by both panda-core and panda-cms
        def run!(options = {})
          config = Config.new(
            engine_label: options.fetch(:engine_label),
            engine_root: Pathname(options.fetch(:engine_root)),
            engine_js_subpath: options.fetch(:engine_js_subpath), # e.g. "panda/core" or "panda/cms"
            dummy_root: Pathname(options.fetch(:dummy_root) { find_dummy_root }),
            rails_env: options.fetch(:rails_env, "test")
          )

          report = Report.new(config)

          report.banner(" #{config.engine_label} dummy assets – PREPARE + VERIFY ")

          preparer = Preparer.new(config, report)
          verifier = Verifier.new(config, report)

          prepare_ok = preparer.prepare!
          verify_ok = prepare_ok ? verifier.verify! : false

          report.finish!(prepare_ok: prepare_ok, verify_ok: verify_ok)
        end
      end
    end
  end
end
