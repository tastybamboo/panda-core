# frozen_string_literal: true

require "net/http"
require "json"

module Panda
  module Assets
    class Verifier
      def initialize(config)
        @config = config
        @public_root = config[:public_root]
      end

      def call
        details = []
        ok = true

        manifest = @public_root.join("assets/.manifest.json")

        unless manifest.exist?
          ok = false
          details << "Manifest missing"
          return {ok: ok, details: details}
        end

        parsed = JSON.parse(File.read(manifest))
        details << "Manifest entries: #{parsed.keys.size}"

        # Try HTTP-serving from mini server
        pid = spawn_http_server

        sleep 0.3
        begin
          parsed.each_key do |fp|
            path = "/assets/#{fp}"
            code = http_get_code(path)
            if code != 200
              ok = false
              details << "HTTP missing: #{path} (#{code})"
            end
          end
        ensure
          Process.kill("TERM", pid)
        end

        {ok: ok, details: details}
      end

      def spawn_http_server
        Process.spawn(
          "ruby",
          "-run",
          "-e",
          "httpd",
          @public_root.to_s,
          "-p",
          "4579"
        )
      end

      def http_get_code(path)
        Net::HTTP.start("127.0.0.1", 4579) do |http|
          http.request_head(path).code.to_i
        end
      rescue
        0
      end
    end
  end
end
