# frozen_string_literal: true

require "tmpdir"

module Panda
  module Core
    module Testing
      module Support
        module System
          # HOME override (macOS sandboxed environments)
          #
          # Ensures HOME directory is writable for Chrome/Chromium to create user data directories.
          # This is especially important in CI environments and sandboxed macOS environments.
          module HomeDir
            class << self
              def original_home
                @original_home ||= ENV["HOME"]
              end

              def ensure_writable_home!
                home = ENV["HOME"].to_s

                if home.empty? || ENV["CI"] || !File.writable?(home)
                  new_home =
                    if ENV["CI"]
                      Dir.mktmpdir("panda-home", "/tmp")
                    else
                      Dir.mktmpdir("panda-home")
                    end

                  ENV["HOME"] = new_home
                  puts "🐼 HOME overridden → #{new_home}"
                end
              end

              def restore_home!
                return unless original_home
                ENV["HOME"] = original_home
              end
            end
          end
        end
      end
    end
  end
end
