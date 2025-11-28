# frozen_string_literal: true

module Panda
  module Core
    #
    # Panda::Core::Middleware
    #
    # A robust, Rails-8-safe middleware manipulation system intended for use
    # inside Rails Engines. Rails 7/8 freeze the middleware stack earlier than
    # before, which breaks classic insert_before / insert_after calls.
    #
    # This module solves:
    #   - FrozenError (“can't modify frozen Array”)
    #   - Missing target middleware in Rails 8 (ActionDispatch::Static)
    #   - Rack 3 builder incompatibility
    #   - Differences between engine load order in test vs host app
    #
    # Features:
    #
    #   ✔ Priority-based insertion (first matching target wins)
    #   ✔ Automatic graceful fallback when targets are missing
    #   ✔ Rebuilds the middleware stack safely
    #   ✔ Works inside Rails engines where the stack is incomplete at boot
    #   ✔ Clean log output when a target cannot be found
    #
    #
    # Example:
    #
    #   Panda::Core::Middleware.insert_before(
    #     app,
    #     [ActionDispatch::Static, Rack::Sendfile],
    #     Rack::Static,
    #     urls: ["/panda-assets"],
    #     root: Panda::Core::Engine.root.join("public")
    #   )
    #
    #
    module Middleware
      module_function

      # ─────────────────────────────────────────────────────────
      # Public API
      # ─────────────────────────────────────────────────────────

      def insert_before(app, targets, middleware, *args, **kwargs)
        resolved_target = resolve_target(app, targets, :insert_before)
        rebuild_middleware(app) do |stack|
          idx = find_index(stack, resolved_target) || fallback_before(stack)
          stack.insert(idx, [middleware, args, kwargs])
        end
      end

      def insert_after(app, targets, middleware, *args, **kwargs)
        resolved_target = resolve_target(app, targets, :insert_after)
        rebuild_middleware(app) do |stack|
          idx = find_index(stack, resolved_target) || fallback_after(stack)
          stack.insert(idx + 1, [middleware, args, kwargs])
        end
      end

      def use(app, middleware, *args, **kwargs)
        rebuild_middleware(app) { |stack| stack << [middleware, args, kwargs] }
      end

      # ─────────────────────────────────────────────────────────
      # Target resolution
      # ─────────────────────────────────────────────────────────

      def resolve_target(app, targets, op)
        Array(targets).each do |target|
          return target if middleware_exists?(app, target)
        end

        warn_missing(targets, op)
        nil
      end

      def middleware_exists?(app, target)
        app.config.middleware.any? do |mw|
          klass = mw.respond_to?(:klass) ? mw.klass : mw
          match?(klass, target)
        end
      end

      # ─────────────────────────────────────────────────────────
      # Fallback positions
      # ─────────────────────────────────────────────────────────

      def fallback_before(stack)
        find_index(stack, ActionDispatch::Executor) || 0
      end

      def fallback_after(stack)
        find_index(stack, ActionDispatch::Executor) || (stack.length - 1)
      end

      # ─────────────────────────────────────────────────────────
      # Stack rebuilding
      # ─────────────────────────────────────────────────────────

      def rebuild_middleware(app)
        original = app.config.middleware

        new_stack = original.map do |mw|
          [
            (mw.respond_to?(:klass) ? mw.klass : mw),
            (mw.respond_to?(:args) ? mw.args : []),
            (mw.respond_to?(:kwargs) ? mw.kwargs : {})
          ]
        end

        yield new_stack

        original.clear
        new_stack.each do |klass, args, kwargs|
          original.use klass, *args, **kwargs
        end
      end

      # ─────────────────────────────────────────────────────────
      # Stack scanning
      # ─────────────────────────────────────────────────────────

      def find_index(stack, target)
        return nil unless target
        stack.index { |(klass, _args, _kwargs)| match?(klass, target) }
      end

      def match?(klass, target)
        klass == target ||
          klass.to_s == target.to_s ||
          (klass.respond_to?(:name) && klass.name.to_s == target.to_s)
      end

      # ─────────────────────────────────────────────────────────
      # Logging
      # ─────────────────────────────────────────────────────────

      def warn_missing(targets, op)
        Rails.logger.warn(
          "⚠️  Panda::Core::Middleware.#{op}: none of #{targets.inspect} found, using fallback"
        )
      rescue
        puts "⚠️  Panda::Core::Middleware.#{op}: none of #{targets.inspect} found, using fallback"
      end
    end
  end
end
