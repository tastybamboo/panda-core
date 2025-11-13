# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module Assets
        module UI
          module_function

          def colour_enabled?
            $stdout.tty? && ENV["NO_COLOR"].nil?
          end

          def colour(code)
            return "" unless colour_enabled?
            "\e[#{code}m"
          end

          def reset
            colour("0")
          end

          def green(str)
            "#{colour("32")}#{str}#{reset}"
          end

          def red(str)
            "#{colour("31")}#{str}#{reset}"
          end

          def yellow(str)
            "#{colour("33")}#{str}#{reset}"
          end

          def cyan(str)
            "#{colour("36")}#{str}#{reset}"
          end

          def bold(str)
            "#{colour("1")}#{str}#{reset}"
          end

          def banner(title, status: nil)
            line = "─" * [title.size + 10, 20].max
            puts
            puts cyan("┌#{line}┐")
            label = case status
            when :ok then green("OK")
            when :fail then red("FAIL")
            end
            heading = label ? "[#{label}] #{title}" : title
            puts cyan("│ ") + bold(heading) + cyan(" │")
            puts cyan("└#{line}┘")
          end

          def step(title)
            puts "• #{title}"
          end

          def ok(msg)
            puts "   #{green("✓")} #{msg}"
          end

          def warn(msg)
            puts "   #{yellow("!")} #{msg}"
          end

          def error(msg)
            puts "   #{red("✗")} #{msg}"
          end

          def divider
            puts cyan("-" * 60)
          end
        end
      end
    end
  end
end
