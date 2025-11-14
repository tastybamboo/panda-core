# frozen_string_literal: true

require "fileutils"

module Panda
  module Assets
    class Preparer
      def initialize(config)
        @config = config
        @dummy = config[:dummy_root]
        @engine_root = config[:engine_root]
      end

      def call
        details = []
        ok = true

        #
        # 1. Propshaft compile
        #
        begin
          details << "Compiling Propshaft assets"
          Dir.chdir(@dummy) do
            system({"RAILS_ENV" => "test"}, "bin/rails assets:precompile")
          end
        rescue => e
          ok = false
          details << "Propshaft compile failed: #{e.message}"
        end

        #
        # 2. Copy JS sources
        #
        Array(@config[:javascript_paths]).each do |rel|
          src = @engine_root.join(rel)
          dst = @dummy.join(rel)
          FileUtils.mkdir_p dst
          FileUtils.cp_r Dir["#{src}/*"], dst, remove_destination: true
          details << "Copied JS: #{src}"
        end

        #
        # 3. Copy vendor/javascript
        #
        Array(@config[:vendor_paths]).each do |rel|
          src = @engine_root.join(rel)
          next unless src.exist?

          dst = @dummy.join(rel)
          FileUtils.mkdir_p dst
          FileUtils.cp_r Dir["#{src}/*"], dst, remove_destination: true
          details << "Copied vendor JS: #{src}"
        end

        {ok: ok, details: details}
      end
    end
  end
end
