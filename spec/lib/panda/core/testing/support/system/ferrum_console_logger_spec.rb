# frozen_string_literal: true

require "rails_helper"
require "panda/core/testing/support/system/ferrum_console_logger"

RSpec.describe Panda::Core::Testing::Support::System::FerrumConsoleLogger do
  subject(:logger) { described_class.new }

  describe "#puts" do
    it "captures console.log messages" do
      cdp_event = 'RECV 1 {"method": "Runtime.consoleAPICalled", "params": {"type": "log", "args": [{"type": "string", "value": "Test message"}]}}'

      logger.puts(cdp_event)

      expect(logger.logs.count).to eq(1)
      expect(logger.logs.first.level).to eq("log")
      expect(logger.logs.first.message).to eq("Test message")
    end

    it "captures console.error messages" do
      cdp_event = 'RECV 2 {"method": "Runtime.consoleAPICalled", "params": {"type": "error", "args": [{"type": "string", "value": "Error message"}]}}'

      logger.puts(cdp_event)

      expect(logger.logs.count).to eq(1)
      expect(logger.logs.first.level).to eq("error")
      expect(logger.logs.first.message).to eq("Error message")
    end

    it "captures JavaScript exceptions" do
      cdp_event = 'RECV 3 {"method": "Runtime.exceptionThrown", "params": {"exceptionDetails": {"text": "Uncaught Error", "exception": {"description": "ReferenceError: foo is not defined"}, "url": "http://localhost/test.js", "lineNumber": 42}}}'

      logger.puts(cdp_event)

      expect(logger.logs.count).to eq(1)
      expect(logger.logs.first.message).to include("ReferenceError: foo is not defined")
      expect(logger.logs.first.message).to include("http://localhost/test.js:42")
    end

    it "ignores non-console CDP events" do
      cdp_event = 'RECV 4 {"method": "Network.responseReceived", "params": {"response": {"url": "http://localhost"}}}'

      logger.puts(cdp_event)

      expect(logger.logs.count).to eq(0)
    end

    it "handles malformed JSON gracefully" do
      logger.puts("SEND 5 {invalid json}")

      expect(logger.logs.count).to eq(0)
    end

    it "handles non-string input gracefully" do
      logger.puts(nil)
      logger.puts(123)
      logger.puts({})

      expect(logger.logs.count).to eq(0)
    end
  end

  describe "#clear" do
    it "removes all captured logs" do
      cdp_event = 'RECV 1 {"method": "Runtime.consoleAPICalled", "params": {"type": "log", "args": [{"type": "string", "value": "Test"}]}}'
      logger.puts(cdp_event)

      expect(logger.logs.count).to eq(1)

      logger.clear

      expect(logger.logs.count).to eq(0)
    end
  end

  describe "Message#to_s" do
    it "formats messages with level and content" do
      cdp_event = 'RECV 1 {"method": "Runtime.consoleAPICalled", "params": {"type": "warning", "args": [{"type": "string", "value": "Warning message"}]}}'
      logger.puts(cdp_event)

      expect(logger.logs.first.to_s).to eq("[WARNING] Warning message")
    end
  end

  describe "Message#format_argument" do
    let(:message) do
      cdp_event = 'RECV 1 {"method": "Runtime.consoleAPICalled", "params": {"type": "log", "args": []}}'
      logger.puts(cdp_event)
      logger.logs.first
    end

    it "formats string arguments" do
      arg = {"type" => "string", "value" => "test"}
      expect(message.format_argument(arg)).to eq("test")
    end

    it "formats number arguments" do
      arg = {"type" => "number", "value" => 42}
      expect(message.format_argument(arg)).to eq("42")
    end

    it "formats boolean arguments" do
      arg = {"type" => "boolean", "value" => true}
      expect(message.format_argument(arg)).to eq("true")
    end

    it "formats undefined" do
      arg = {"type" => "undefined"}
      expect(message.format_argument(arg)).to eq("undefined")
    end

    it "formats null objects" do
      arg = {"type" => "object", "subtype" => "null"}
      expect(message.format_argument(arg)).to eq("null")
    end

    it "formats other objects" do
      arg = {"type" => "object", "description" => "{foo: 'bar'}"}
      expect(message.format_argument(arg)).to eq("{foo: 'bar'}")
    end
  end
end
