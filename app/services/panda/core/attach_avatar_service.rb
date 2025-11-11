# frozen_string_literal: true

require "open-uri"

module Panda
  module Core
    class AttachAvatarService < Services::BaseService
      MAX_FILE_SIZE = 5.megabytes
      MAX_DIMENSION = 800 # Max width/height for optimization

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
          if downloaded_file.size > MAX_FILE_SIZE
            raise "Avatar file too large (#{downloaded_file.size} bytes)"
          end

          # Determine content type and filename
          content_type = downloaded_file.content_type || "image/jpeg"

          # Optimize and attach the avatar
          optimized_file = optimize_image(downloaded_file, content_type)

          filename = "avatar_#{@user.id}_#{Time.current.to_i}.webp"

          # Attach the optimized avatar
          @user.avatar.attach(
            io: optimized_file,
            filename: filename,
            content_type: "image/webp"
          )
        end
        # standard:enable Security/Open
      end

      def optimize_image(file, content_type)
        processor = Panda::Core.config.avatar_image_processor
        loader = load_image_processor(processor)
        return file unless loader

        begin
          processed = loader
            .source(file)
            .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
            .convert("webp")
            .saver(quality: 85, strip: true) # Strip metadata, 85% quality
            .call

          # Return File object
          File.open(processed.path)
        rescue => e
          Rails.logger.warn("Image optimization failed (#{processor}), using original: #{e.message}")
          # Fallback to original file if optimization fails
          file
        end
      end

      def load_image_processor(processor)
        case processor
        when :vips
          require "image_processing/vips"
          ImageProcessing::Vips
        when :mini_magick
          require "image_processing/mini_magick"
          ImageProcessing::MiniMagick
        else
          Rails.logger.warn("Unknown image processor: #{processor}, avatar optimization disabled")
          nil
        end
      rescue LoadError => e
        Rails.logger.warn("Image processor #{processor} not available: #{e.message}")
        nil
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
