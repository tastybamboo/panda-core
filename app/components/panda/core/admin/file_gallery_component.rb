# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FileGalleryComponent < Panda::Core::Base
        def initialize(selected_file: nil, files: [], **attrs)
          @files = files
          @selected_file = selected_file
          super(**attrs)
        end

        attr_reader :files, :selected_file

        private

        def render_gallery
          # Implemented in ERB template
        end

        def render_file_item(file)
          @selected_file && @selected_file.id == file.id
          # Implemented in ERB template
        end

        def file_container_classes(selected)
          base = "group overflow-hidden rounded-lg bg-gray-100 dark:bg-gray-800"
          focus = if selected
            "outline-2 outline-offset-2 outline-panda-dark dark:outline-panda-light outline"
          else
            "focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-indigo-600 dark:focus-within:outline-indigo-500"
          end
          "#{base} #{focus}"
        end

        def file_image_classes(selected)
          base = "pointer-events-none aspect-10/7 rounded-lg object-cover outline -outline-offset-1 outline-black/5 dark:outline-white/10"
          hover = selected ? "" : "group-hover:opacity-75"
          "#{base} #{hover}"
        end

        def render_file_icon(file)
          # Implemented in ERB template
        end

        def render_empty_state
          # Implemented in ERB template
        end

        # Helper method to generate URL for ActiveStorage attachment
        def url_for(file)
          if defined?(Rails) && Rails.application.routes.url_helpers.respond_to?(:rails_blob_path)
            Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
          else
            "#"
          end
        rescue
          "#"
        end

        # Helper method for human-readable file sizes
        def number_to_human_size(size)
          return "0 Bytes" if size.zero?

          units = ["Bytes", "KB", "MB", "GB", "TB"]
          exp = (Math.log(size) / Math.log(1024)).to_i
          exp = [exp, units.length - 1].min

          "%.1f %s" % [size.to_f / (1024**exp), units[exp]]
        end
      end
    end
  end
end
