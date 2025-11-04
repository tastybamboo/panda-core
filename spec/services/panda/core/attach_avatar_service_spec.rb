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
          read: "fake_image_data"
        )
      end

      before do
        allow(URI).to receive(:open).and_yield(downloaded_file)
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

      it "updates oauth_avatar_url on user" do
        service.call
        expect(user.reload.oauth_avatar_url).to eq(avatar_url)
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

    describe "content type detection" do
      let(:test_cases) do
        {
          "image/jpeg" => ".jpg",
          "image/jpg" => ".jpg",
          "image/png" => ".png",
          "image/gif" => ".gif",
          "image/webp" => ".webp",
          "image/unknown" => ".jpg"
        }
      end

      it "determines correct file extension for various content types" do
        test_cases.each do |content_type, expected_extension|
          downloaded_file = double(
            "downloaded_file",
            size: 1.megabyte,
            content_type: content_type,
            read: "fake_image_data"
          )

          allow(URI).to receive(:open).and_yield(downloaded_file)
          allow(user.avatar).to receive(:attach) do |options|
            expect(options[:filename]).to end_with(expected_extension)
          end

          service.call
        end
      end
    end
  end
end
