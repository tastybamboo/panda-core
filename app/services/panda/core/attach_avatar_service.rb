# frozen_string_literal: true

require "open-uri"

module Panda
  module Core
    class AttachAvatarService < Services::BaseService
      def initialize(user:, avatar_url:)
        @user = user
        @avatar_url = avatar_url
      end

      def call
        return success if @avatar_url.blank?
        return success if @avatar_url == @user.oauth_avatar_url && @user.avatar.attached?

        begin
          download_and_attach_avatar
          @user.update_column(:oauth_avatar_url, @avatar_url)
          success(avatar_attached: true)
        rescue => e
          Rails.logger.error("Failed to attach avatar for user #{@user.id}: #{e.message}")
          failure(["Failed to attach avatar: #{e.message}"])
        end
      end

      private

      def download_and_attach_avatar
        # Open the URL with a timeout and size limit
        # standard:disable Security/Open
        # Safe in this context as URL comes from trusted OAuth providers (Microsoft, Google, GitHub)
        URI.open(@avatar_url, read_timeout: 10, open_timeout: 10, redirect: true) do |downloaded_file|
          # standard:enable Security/Open
          # Validate file size (max 5MB)
          if downloaded_file.size > 5.megabytes
            raise "Avatar file too large (#{downloaded_file.size} bytes)"
          end

          # Determine content type and filename
          content_type = downloaded_file.content_type || "image/jpeg"
          extension = determine_extension(content_type)
          filename = "avatar_#{@user.id}_#{Time.current.to_i}#{extension}"

          # Attach the avatar
          @user.avatar.attach(
            io: downloaded_file,
            filename: filename,
            content_type: content_type
          )
        end
        # standard:enable Security/Open
      end

      def determine_extension(content_type)
        case content_type
        when /jpeg|jpg/
          ".jpg"
        when /png/
          ".png"
        when /gif/
          ".gif"
        when /webp/
          ".webp"
        else
          ".jpg"
        end
      end
    end
  end
end
