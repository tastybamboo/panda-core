# frozen_string_literal: true

require "action_dispatch"

module Rails
  module Configuration
    # Add a tiny compatibility layer so the proxy can be inspected and reset in tests.
    class MiddlewareStackProxy
      include Enumerable

      def clear
        operations.clear
        delete_operations.clear
        self
      end

      def each(&block)
        to_stack.each { |mw| block.call(wrap_middleware(mw)) }
      end

      def to_a
        map(&:itself)
      end

      def [](index)
        to_a[index]
      end

      def first
        to_a.first
      end

      def last
        to_a.last
      end

      def size
        to_a.size
      end

      private

      def to_stack
        ActionDispatch::MiddlewareStack.new.tap do |stack|
          merge_into(stack)
        end
      end

      def wrap_middleware(middleware)
        args, kwargs = split_args_and_kwargs(middleware.args)
        MiddlewareEntry.new(middleware.klass, args, kwargs, middleware.block)
      end

      def split_args_and_kwargs(args)
        return [args, {}] unless args.last.is_a?(Hash)

        [args[0...-1], args.last]
      end

      MiddlewareEntry = Struct.new(:klass, :args, :kwargs, :block)
    end
  end
end

module Panda
  module Core
    module Middleware
      EXECUTOR = "ActionDispatch::Executor"

      def self.use(app, klass, *args, **kwargs, &block)
        app.config.middleware.use(klass, *args, **kwargs, &block)
      end

      def self.insert_before(app, priority_targets, klass, *args, **kwargs, &block)
        stack = build_stack(app)
        target = resolve_target(stack, priority_targets, :insert_before)
        insertion_point = target || fallback_before(stack)
        app.config.middleware.insert_before(insertion_point, klass, *args, **kwargs, &block)
      end

      def self.insert_after(app, priority_targets, klass, *args, **kwargs, &block)
        stack = build_stack(app)
        target = resolve_target(stack, priority_targets, :insert_after)
        insertion_point = target || fallback_after(stack)
        app.config.middleware.insert_after(insertion_point, klass, *args, **kwargs, &block)
      end

      #
      # Helpers
      #
      def self.resolve_target(app_or_stack, priority_targets, _operation)
        stack = normalize_stack(app_or_stack)
        priority_targets.find { |candidate| middleware_exists?(stack, candidate) }
      end
      private_class_method :resolve_target

      def self.middleware_exists?(app_or_stack, candidate)
        stack = normalize_stack(app_or_stack)
        stack.any? { |mw| middleware_matches?(mw.klass, candidate) }
      end
      private_class_method :middleware_exists?

      def self.middleware_matches?(klass, candidate)
        klass == candidate || klass.name == candidate.to_s
      end
      private_class_method :middleware_matches?

      def self.fallback_before(stack)
        executor_index = index_for(stack, EXECUTOR)
        executor_index || 0
      end
      private_class_method :fallback_before

      def self.fallback_after(stack)
        executor_index = index_for(stack, EXECUTOR)
        return executor_index + 1 if executor_index

        stack_size = stack.size
        stack_size.zero? ? 0 : stack_size - 1
      end
      private_class_method :fallback_after

      def self.index_for(stack, target)
        stack.each_with_index do |middleware, idx|
          return idx if middleware_matches?(middleware.klass, target)
        end
        nil
      end
      private_class_method :index_for

      def self.build_stack(app)
        app.config.middleware.to_a
      end
      private_class_method :build_stack

      def self.normalize_stack(app_or_stack)
        if app_or_stack.respond_to?(:config) && app_or_stack.config.respond_to?(:middleware)
          build_stack(app_or_stack)
        else
          app_or_stack
        end
      end
      private_class_method :normalize_stack
    end
  end
end
