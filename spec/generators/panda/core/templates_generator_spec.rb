require "rails_helper"
require_relative "../../../../lib/generators/panda/core/templates_generator"
require "support/generator_spec_helper"

RSpec.describe Panda::Core::Generators::TemplatesGenerator, type: :generator do
  let(:template_files) do
    template_root = described_class.source_root
    Dir.glob(File.join(template_root, "**/{.*,*}"), File::FNM_DOTMATCH)
      .reject { |f| File.directory?(f) }
      .reject { |f| File.basename(f) == "." || File.basename(f) == ".." }
      .map { |f| Pathname.new(f).relative_path_from(Pathname.new(template_root)).to_s }
  end

  let(:missing_file) { ".missing_config.yml" }

  let(:expected_config_files) do
    [
      ".standard.yml",
      ".gitignore",
      ".erb_lint.yml",
      ".yamllint"
    ]
  end

  describe "copying files" do
    it "copies all template files" do
      run_generator

      template_files.each do |file|
        # Check if file exists in source first
        source_path = File.join(described_class.source_root, file)
        expect(File).to exist(source_path), "Expected #{file} to exist in source: #{source_path}"

        # Then check if it was copied to destination
        dest_path = File.join(destination_root, file)
        # Create directory if it doesn't exist, ignore if it does
        begin
          FileUtils.mkdir_p(File.dirname(dest_path))
        rescue Errno::EEXIST
          # Directory already exists, that's fine
        end
        expect(File).to exist(dest_path), "Expected #{file} to exist in destination: #{dest_path}"
      end
    end

    it "copies all configuration files" do
      # Get absolute paths and verify template directory
      template_root = File.expand_path(described_class.source_root)

      # Check source files before running generator
      expected_config_files.each do |file|
        source_path = File.join(template_root, file)
        expect(File).to exist(source_path),
          "Expected #{file} to exist in #{source_path}"
      end

      run_generator

      # Check destination files after running generator
      expected_config_files.each do |file|
        dest_path = File.join(destination_root, file)
        expect(File).to exist(dest_path),
          "Expected #{file} to exist in #{destination_root}"
      end
    end
  end

  describe "error handling" do
    it "raises an error when trying to copy a missing file" do
      generator = described_class.new([], destination_root: destination_root)
      template_root = described_class.source_root
      missing_file_path = File.join(template_root, missing_file)

      # Mock the Dir.glob to return our missing file with full path
      allow(Dir).to receive(:glob)
        .with(File.join(described_class.source_root, "**/{.*,*}"), File::FNM_DOTMATCH)
        .and_return([missing_file_path])

      # Stub File.directory? to return false for the missing file
      allow(File).to receive(:directory?).with(missing_file_path).and_return(false)

      # Stub File.basename to work normally
      allow(File).to receive(:basename).and_call_original

      # Stub the copy_file method to raise an error for our missing file
      allow(generator).to receive(:copy_file)
        .with(missing_file)
        .and_raise(Thor::Error, "Source file not found: #{missing_file}")

      expect {
        generator.copy_templates
      }.to raise_error(Thor::Error, /Source file not found: .*#{missing_file}/)
    end
  end
end
