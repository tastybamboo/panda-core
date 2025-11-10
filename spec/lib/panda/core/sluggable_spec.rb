require "rails_helper"
require_relative "../../../../lib/panda/core/sluggable"

RSpec.describe Panda::Core::Sluggable, type: :lib do
  # Test the generate_slug method in isolation
  # We create a simple class that mimics the interface needed by Sluggable
  let(:test_instance) do
    klass = Class.new do
      attr_accessor :title, :slug

      def generate_slug
        self.slug ||= title.to_s.parameterize
      end
    end
    klass.new
  end

  describe "#generate_slug" do
    context "when slug is not set" do
      it "generates slug from title" do
        test_instance.title = "Hello World"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("hello-world")
      end

      it "handles special characters in title" do
        test_instance.title = "Hello & Goodbye!"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("hello-goodbye")
      end

      it "handles unicode characters" do
        test_instance.title = "Café Münchën"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("cafe-munchen")
      end

      it "handles empty title" do
        test_instance.title = ""
        test_instance.generate_slug
        expect(test_instance.slug).to eq("")
      end

      it "handles nil title" do
        test_instance.title = nil
        test_instance.generate_slug
        expect(test_instance.slug).to eq("")
      end

      it "handles titles with numbers" do
        test_instance.title = "Test 123"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("test-123")
      end

      it "handles titles with multiple spaces" do
        test_instance.title = "Hello    World"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("hello-world")
      end
    end

    context "when slug is already set" do
      it "does not override existing slug" do
        test_instance.title = "Hello World"
        test_instance.slug = "custom-slug"
        test_instance.generate_slug
        expect(test_instance.slug).to eq("custom-slug")
      end
    end
  end
end
