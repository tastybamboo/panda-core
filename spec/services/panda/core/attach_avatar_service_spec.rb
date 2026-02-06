require "rails_helper"

RSpec.describe Panda::Core::AttachAvatarService, type: :service do
  let(:user) { Panda::Core::User.create!(email: "test@example.com", name: "Test User") }
  let(:avatar_url) { "https://example.com/avatar.jpg" }
  let(:service) { described_class.new(user: user, avatar_url: avatar_url) }

  describe "#call" do
    context "when avatar_url is blank" do
      let(:avatar_url) { "" }

      it "returns success without attaching avatar" do
        result = service.call
        expect(result.success?).to be true
        expect(user.avatar.attached?).to be false
      end
    end

    context "when avatar URL matches existing oauth_avatar_url and avatar is attached" do
      before do
        user.update_column(:oauth_avatar_url, avatar_url)
        user.avatar.attach(io: File.open(Panda::Core::Engine.root.join("spec", "fixtures", "files", "test_image.jpg")), filename: "test.jpg", content_type: "image/jpeg")
      end

      it "returns success without re-downloading" do
        expect(URI).not_to receive(:open)
        result = service.call
        expect(result.success?).to be true
      end
    end

    context "when avatar URL is new" do
      let(:downloaded_file) do
        double(
          "downloaded_file",
          size: 1.megabyte,
          content_type: "image/jpeg",
          read: "fake_image_data",
          path: "/tmp/test.jpg"
        )
      end

      let(:optimized_file) do
        double("optimized_file", path: "/tmp/optimized.webp")
      end

      before do
        allow(URI).to receive(:open).and_yield(downloaded_file)
        allow(ImageProcessing::Vips).to receive_message_chain(:source, :resize_to_limit, :convert, :saver, :call).and_return(optimized_file)
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(optimized_file.path).and_return(optimized_file)
        allow(user.avatar).to receive(:attach)
      end

      it "downloads and attaches the avatar" do
        expect(URI).to receive(:open).with(
          avatar_url,
          read_timeout: 10,
          open_timeout: 10,
          redirect: true
        )

        result = service.call
        expect(result.success?).to be true
        expect(result.payload[:avatar_attached]).to be true
      end

      it "optimizes the image using vips" do
        expect(ImageProcessing::Vips).to receive(:source).with(downloaded_file).and_call_original
        service.call
      end

      it "converts image to WebP format" do
        expect(user.avatar).to receive(:attach) do |options|
          expect(options[:content_type]).to eq("image/webp")
          expect(options[:filename]).to end_with(".webp")
        end
        service.call
      end

      it "updates oauth_avatar_url on user" do
        service.call
        expect(user.reload.oauth_avatar_url).to eq(avatar_url)
      end

      it "clears image_url after successful attachment" do
        user.update_column(:image_url, "https://example.com/old-image.jpg")
        service.call
        expect(user.reload.image_url).to be_nil
      end
    end

    context "when file size exceeds limit" do
      let(:downloaded_file) do
        double("downloaded_file", size: 6.megabytes, content_type: "image/jpeg")
      end

      before do
        allow(URI).to receive(:open).and_yield(downloaded_file)
      end

      it "returns failure" do
        result = service.call
        expect(result.success?).to be false
        expect(result.errors).to include(/Avatar file too large/)
      end
    end

    context "when download fails" do
      before do
        allow(URI).to receive(:open).and_raise(StandardError.new("Network error"))
      end

      it "returns failure and logs error" do
        expect(Rails.logger).to receive(:error).with(/Failed to attach avatar/)
        result = service.call
        expect(result.success?).to be false
        expect(result.errors).to include(/Failed to attach avatar/)
      end
    end

    describe "image optimization" do
      context "when optimization succeeds" do
        let(:downloaded_file) do
          double("downloaded_file", size: 1.megabyte, content_type: "image/jpeg", path: "/tmp/test.jpg")
        end

        let(:optimized_file) do
          double("optimized_file", path: "/tmp/optimized.webp")
        end

        before do
          allow(URI).to receive(:open).and_yield(downloaded_file)
          allow(ImageProcessing::Vips).to receive_message_chain(:source, :resize_to_limit, :convert, :saver, :call).and_return(optimized_file)
          allow(File).to receive(:open).and_call_original
          allow(File).to receive(:open).with(optimized_file.path).and_return(optimized_file)
          allow(user.avatar).to receive(:attach)
        end

        it "resizes image to max dimension" do
          vips_chain = double
          expect(ImageProcessing::Vips).to receive(:source).and_return(vips_chain)
          expect(vips_chain).to receive(:resize_to_limit).with(800, 800).and_return(vips_chain)
          expect(vips_chain).to receive(:convert).with("webp").and_return(vips_chain)
          expect(vips_chain).to receive(:saver).with(quality: 85, strip: true).and_return(vips_chain)
          expect(vips_chain).to receive(:call).and_return(optimized_file)

          service.call
        end

        it "strips metadata and sets quality to 85%" do
          vips_chain = double
          allow(ImageProcessing::Vips).to receive(:source).and_return(vips_chain)
          allow(vips_chain).to receive(:resize_to_limit).and_return(vips_chain)
          allow(vips_chain).to receive(:convert).and_return(vips_chain)
          expect(vips_chain).to receive(:saver).with(quality: 85, strip: true).and_return(vips_chain)
          allow(vips_chain).to receive(:call).and_return(optimized_file)

          service.call
        end
      end

      context "when optimization fails" do
        let(:downloaded_file) do
          double("downloaded_file", size: 1.megabyte, content_type: "image/jpeg", path: "/tmp/test.jpg")
        end

        before do
          allow(URI).to receive(:open).and_yield(downloaded_file)
          allow(ImageProcessing::Vips).to receive(:source).and_raise(StandardError.new("Processing error"))
          allow(user.avatar).to receive(:attach)
        end

        it "falls back to original file and logs warning" do
          expect(Rails.logger).to receive(:warn).with(/Image optimization failed/)
          expect(user.avatar).to receive(:attach).with(hash_including(io: downloaded_file))
          service.call
        end
      end
    end
  end
end
