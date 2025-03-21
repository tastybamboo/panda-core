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
    Rails::Generators.invoke(described_class, args, destination_root: destination_root)
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
    original_stream = eval("$#{stream}", binding, __FILE__, __LINE__)
    eval("$#{stream} = captured_stream", binding, __FILE__, __LINE__)
    yield
    captured_stream.string
  ensure
    eval("$#{stream} = original_stream", binding, __FILE__, __LINE__)
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
