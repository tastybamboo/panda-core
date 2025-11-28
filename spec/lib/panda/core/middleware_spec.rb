# frozen_string_literal: true

require "rails"
require "panda/core/middleware"

RSpec.describe Panda::Core::Middleware do
  # A minimal fake middleware class used for assertions
  # rubocop:disable Lint/ConstantDefinitionInBlock
  class MW1; end
  class MW2; end
  class MW3; end
  class MW4; end
  class CustomStatic; end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  #
  # Build a minimal fake Rails app with a mutable middleware stack.
  #
  let(:app) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = Logger.new(nil)
    end.instance
  end

  #
  # MiddlewareStackProxy stores entries in the form:
  #   [klass, args, kwargs]
  #
  def stack
    app.config.middleware
  end

  before do
    stack.clear
  end

  describe ".use" do
    it "appends middleware to the stack" do
      described_class.use(app, MW1)
      described_class.use(app, MW2, "a", b: 1)

      expect(stack.map(&:klass)).to eq([MW1, MW2])
      expect(stack[1].args).to eq(["a"])
      expect(stack[1].kwargs).to eq(b: 1)
    end
  end

  describe ".insert_before" do
    before do
      stack.use MW1
      stack.use MW2
    end

    it "inserts before an existing target" do
      described_class.insert_before(app, [MW2], MW3)

      expect(stack.map(&:klass)).to eq([MW1, MW3, MW2])
    end

    it "inserts before the first matching target in priority list" do
      described_class.insert_before(app, [MW99, MW2, MW1], MW3)

      # MW2 is the first match
      expect(stack.map(&:klass)).to eq([MW1, MW3, MW2])
    end

    it "falls back to ActionDispatch::Executor when target missing" do
      described_class.insert_before(app, [MW99], MW3)

      expect(stack.first.klass).to eq(MW3)
    end

    it "preserves args and kwargs" do
      described_class.insert_before(app, [MW2], MW3, "xyz", mode: :strict)

      entry = stack[1]
      expect(entry.klass).to eq(MW3)
      expect(entry.args).to eq(["xyz"])
      expect(entry.kwargs).to eq({mode: :strict})
    end
  end

  describe ".insert_after" do
    before do
      stack.use MW1
      stack.use MW2
    end

    it "inserts after an existing target" do
      described_class.insert_after(app, [MW1], MW3)

      expect(stack.map(&:klass)).to eq([MW1, MW3, MW2])
    end

    it "inserts after first match in priority list" do
      described_class.insert_after(app, [MW99, MW2], MW3)

      # MW2 is the first match
      expect(stack.map(&:klass)).to eq([MW1, MW2, MW3])
    end

    it "falls back to after ActionDispatch::Executor when missing" do
      described_class.insert_after(app, [MW99], MW3)

      # no executor present, so fallback index = last
      expect(stack.last.klass).to eq(MW3)
    end
  end

  describe "matching behaviour" do
    before { stack.use MW1 }

    it "matches by class" do
      expect(
        described_class.send(:middleware_exists?, app, MW1)
      ).to be true
    end

    it "matches by string name" do
      expect(
        described_class.send(:middleware_exists?, app, "MW1")
      ).to be true
    end

    it "does not match unrelated class" do
      expect(
        described_class.send(:middleware_exists?, app, MW99 = Class.new)
      ).to be false
    end
  end

  describe "stack rebuilding" do
    it "rebuilds the stack without raising FrozenError" do
      stack.use MW1

      expect {
        described_class.use(app, MW2)
      }.not_to raise_error

      expect(stack.map(&:klass)).to eq([MW1, MW2])
    end

    it "round-trips args & kwargs through rebuild" do
      stack.use MW1, "a", x: 1

      described_class.use(app, MW2, "b", y: 9)

      expect(stack[0].args).to eq(["a"])
      expect(stack[0].kwargs).to eq(x: 1)
      expect(stack[1].args).to eq(["b"])
      expect(stack[1].kwargs).to eq(y: 9)
    end
  end

  describe "target resolution" do
    before { stack.use MW1 }

    it "returns the first matching target" do
      target = described_class.send(:resolve_target, app, [MW99, MW1], :insert)
      expect(target).to eq(MW1)
    end

    it "returns nil when nothing matches" do
      target = described_class.send(:resolve_target, app, [MW99], :insert)
      expect(target).to be_nil
    end
  end

  describe "fallback insertion" do
    before do
      stack.use MW1
      stack.use MW2
      # no ActionDispatch::Executor present
    end

    it "fallback_before returns index 0" do
      idx = described_class.send(:fallback_before, stack)
      expect(idx).to eq(0)
    end

    it "fallback_after returns last index" do
      idx = described_class.send(:fallback_after, stack)
      expect(idx).to eq(1)
    end
  end
end
