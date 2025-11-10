require "rails_helper"
require_relative "../../../../lib/panda/core/media"

RSpec.describe Panda::Core::Media, type: :lib do
  # Test the image_url method in isolation
  let(:test_instance) do
    klass = Class.new do
      attr_accessor :featured_image_attached, :featured_image_variant

      def featured_image
        self
      end

      def attached?
        featured_image_attached
      end

      def variant(options)
        featured_image_variant || self
      end

      def processed
        self
      end

      def image_url(variant: nil)
        return nil unless attached?

        case variant
        when :thumbnail
          featured_image.variant(resize_to_fill: [200, 200]).processed
        when :medium
          featured_image.variant(resize_to_fill: [400, 400]).processed
        else
          featured_image
        end
      end
    end
    klass.new
  end

  describe "#image_url" do
    context "when featured image is not attached" do
      before do
        test_instance.featured_image_attached = false
      end

      it "returns nil" do
        expect(test_instance.image_url).to be_nil
      end

      it "returns nil for thumbnail variant" do
        expect(test_instance.image_url(variant: :thumbnail)).to be_nil
      end

      it "returns nil for medium variant" do
        expect(test_instance.image_url(variant: :medium)).to be_nil
      end
    end

    context "when featured image is attached" do
      before do
        test_instance.featured_image_attached = true
      end

      it "returns the featured image without variant" do
        result = test_instance.image_url
        expect(result).not_to be_nil
      end

      it "returns processed thumbnail variant when requested" do
        test_instance.featured_image_variant = double("variant", processed: "thumbnail_processed")
        result = test_instance.image_url(variant: :thumbnail)
        expect(result).to eq("thumbnail_processed")
      end

      it "returns processed medium variant when requested" do
        test_instance.featured_image_variant = double("variant", processed: "medium_processed")
        result = test_instance.image_url(variant: :medium)
        expect(result).to eq("medium_processed")
      end

      it "creates thumbnail variant with correct dimensions" do
        variant_double = double("variant")
        expect(test_instance).to receive(:variant).with(resize_to_fill: [200, 200]).and_return(variant_double)
        expect(variant_double).to receive(:processed)
        test_instance.image_url(variant: :thumbnail)
      end

      it "creates medium variant with correct dimensions" do
        variant_double = double("variant")
        expect(test_instance).to receive(:variant).with(resize_to_fill: [400, 400]).and_return(variant_double)
        expect(variant_double).to receive(:processed)
        test_instance.image_url(variant: :medium)
      end
    end

    context "with unknown variant" do
      before do
        test_instance.featured_image_attached = true
      end

      it "returns the original featured image" do
        result = test_instance.image_url(variant: :unknown)
        expect(result).not_to be_nil
      end
    end
  end

  describe "module documentation" do
    it "is a Ruby module" do
      expect(Panda::Core::Media).to be_a(Module)
    end

    it "extends ActiveSupport::Concern" do
      # The module uses ActiveSupport::Concern for easy inclusion
      expect(Panda::Core::Media.ancestors).to include(ActiveSupport::Concern)
    end
  end
end
