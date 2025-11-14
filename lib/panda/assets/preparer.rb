# frozen_string_literal: true

require "fileutils"
require "benchmark"
require_relative "ui"

module Panda
  module Assets
    class Preparer
      Result = Struct.new(
        :ok,
        :timings,
        :dummy_root,
        :engine_key,
        :errors,
        keyword_init: true
      )

      attr_reader :engine_key, :config, :dummy_root, :timings, :errors

      # config keys:
      #   :dummy_root      Pathname for dummy app (spec/dummy)
      #   :engine_js_roots [Array<Pathname>] JS roots to copy (app/javascript/panda/<engine>, vendor/javascript/panda/<engine>…)
      def initialize(engine_key, config)
        @engine_key = engine_key
        @config = config
        @dummy_root = config.fetch(:dummy_root)
        @timings = {}
        @errors = []
      end

      def prepare
        Panda::Assets::UI.banner("Preparing dummy assets (#{engine_label})")

        time(:propshaft) { compile_propshaft_assets }
        time(:copy_js) { copy_js_sources }
        time(:importmap) { generate_importmap }

        ok = errors.empty?
        Result.new(
          ok: ok,
          timings: timings,
          dummy_root: dummy_root,
          engine_key: engine_key,
          errors: errors.dup
        )
      rescue => e
        errors << "Unexpected error: #{e.class}: #{e.message}"
        Result.new(ok: false, timings: timings, dummy_root: dummy_root, engine_key: engine_key, errors: errors.dup)
      end

      private

      def engine_label
        "Panda #{engine_key.to_s.split("_").map(&:capitalize).join(" ")}"
      end

      def time(key)
        timings[key] = Benchmark.realtime { yield }.round(2)
      end

      def compile_propshaft_assets
        Panda::Assets::UI.step "Compiling Propshaft assets in dummy app (RAILS_ENV=test)"

        Dir.chdir(dummy_root) do
          env = {"RAILS_ENV" => "test"}
          cmd = "bundle exec rails assets:precompile"

          success = system(env, cmd)
          if success
            Panda::Assets::UI.ok "Propshaft assets compiled"
          else
            errors << "Propshaft precompile failed"
          end
        end
      end

      def copy_js_sources
        js_roots = Array(config[:engine_js_roots]).compact
        return if js_roots.empty?

        Panda::Assets::UI.step "Copying engine JS modules into dummy app"

        js_roots.each do |src_root|
          next unless src_root.directory?

          relative = src_root.relative_path_from(engine_root_for(engine_key))
          dest_root = dummy_root.join(relative)

          FileUtils.mkdir_p(dest_root)
          children = Dir.children(src_root)
          next if children.empty?

          FileUtils.cp_r(children.map { |c| src_root.join(c) }, dest_root)

          Panda::Assets::UI.ok "Copied JS from #{src_root} to #{dest_root}"
        end
      end

      def generate_importmap
        Panda::Assets::UI.step "Generating importmap.json from dummy Rails app"

        Dir.chdir(dummy_root) do
          require dummy_root.join("config/environment").to_s

          importmap = Rails.application.importmap
          json = resolve_importmap_json(importmap)

          assets_dir = dummy_root.join("public/assets")
          FileUtils.mkdir_p(assets_dir)
          path = assets_dir.join("importmap.json")
          File.write(path, json)

          Panda::Assets::UI.ok "Wrote #{path}"
        end
      rescue => e
        errors << "Failed to generate importmap.json: #{e.class}: #{e.message}"
      end

      # Support importmap-rails 1.x and 2.x (Rails 7 & 8)
      def resolve_importmap_json(importmap)
        if importmap.respond_to?(:to_json)
          # Rails 8+ / importmap-rails 2.x already gives JSON with "imports"
          importmap.to_json(
            resolver: ActionController::Base.helpers
          )
        elsif importmap.respond_to?(:entries)
          # Legacy importmap-rails 1.x
          require "json"
          imports = importmap.entries.each_with_object({}) do |entry, h|
            h[entry.name] = entry.to_h[:path] || entry.to_h["path"]
          end
          JSON.pretty_generate("imports" => imports)
        else
          "{}"
        end
      end

      def engine_root_for(key)
        case key
        when :core
          Panda::Core::Engine.root
        when :cms
          Panda::CMS::Engine.root
        else
          Rails.root
        end
      end
    end
  end
end
