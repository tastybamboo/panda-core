require "rails/generators"

module GeneratorSpecHelper
  extend ActiveSupport::Concern

  included do
    before(:each) do
      prepare_destination
      @original_stdout = $stdout
      $stdout = File.new(File::NULL, "w")
    end

    after(:each) do
      FileUtils.rm_rf(destination_root)
      $stdout = @original_stdout
    end
  end

  def destination_root
    @destination_root ||= File.expand_path("../../tmp/generators", __dir__)
  end

  def prepare_destination
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
  end

  def run_generator(args = [])
    args = Array(args)
    # Use the generator namespace instead of class name
    generator_name = described_class.namespace
    Rails::Generators.invoke(generator_name, args, destination_root: destination_root)
  end

  def generator
    @generator ||= described_class.new([], destination_root: destination_root)
  end

  def file_exists?(path)
    File.exist?(File.join(destination_root, path))
  end

  def read_file(path)
    File.read(File.join(destination_root, path))
  end

  private

  def capture(stream)
    stream = stream.to_s
    captured_stream = StringIO.new

    # Map stream names to their global variables to avoid eval
    streams = {
      "stdout" => $stdout,
      "stderr" => $stderr,
      "stdin" => $stdin
    }

    original_stream = streams[stream]
    case stream
    when "stdout"
      $stdout = captured_stream
    when "stderr"
      $stderr = captured_stream
    when "stdin"
      $stdin = captured_stream
    else
      raise ArgumentError, "Unsupported stream: #{stream}"
    end

    yield
    captured_stream.string
  ensure
    case stream
    when "stdout"
      $stdout = original_stream
    when "stderr"
      $stderr = original_stream
    when "stdin"
      $stdin = original_stream
    end
  end
end

RSpec.configure do |config|
  config.include GeneratorSpecHelper, type: :generator

  # Ensure generator tests have a clean environment
  config.before(:each, type: :generator) do
    prepare_destination
  end

  config.after(:each, type: :generator) do
    FileUtils.rm_rf(destination_root) if defined?(destination_root)
  end
end
