require "spec_helper"

RUBY_FILE_PATTERN = File.expand_path("../../**/*.rb", __dir__)
EXCLUDED_PATHS = [
  "db/schema.rb",
  "bin/",
  "script/",
  "log/",
  "public/",
  "tmp/",
  "doc/",
  "vendor/",
  "storage/",
  "node_modules/",
  ".git/",
  "spec/dummy/"
].freeze

RSpec.describe "Reek" do
  it "contains no code smells" do
    failures = []

    Dir.glob(RUBY_FILE_PATTERN).each do |file|
      next if EXCLUDED_PATHS.any? { |path| file.include?(path) }

      IO.popen(["bundle", "exec", "reek", file], err: [:child, :out]) do |io|
        output = io.read
        next if output.empty?

        failures << {file: file, output: output}
      end
    end

    failures.each do |failure|
      puts "\nCode smells found in #{failure[:file]}:"
      puts failure[:output]
    end

    failures.each do |failure|
      expect(failure).to be_nil, "Found code smells in #{failure[:file]}"
    end
  end
end
