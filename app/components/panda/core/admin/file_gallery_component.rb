# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FileGalleryComponent < Panda::Core::Base
        prop :files, _Nilable(Object), default: -> { [] }
        prop :selected_file, _Nilable(Object), default: nil

        def view_template
          if @files.any?
            render_gallery
          else
            render_empty_state
          end
        end

        private

        def render_gallery
          section do
            h2(id: "gallery-heading", class: "sr-only") { "Files" }
            ul(
              role: "list",
              class: "grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
            ) do
              @files.each do |file|
                render_file_item(file)
              end
            end
          end
        end

        def render_file_item(file)
          is_selected = @selected_file && @selected_file.id == file.id

          li(class: "relative") do
            div(
              class: file_container_classes(is_selected)
            ) do
              if file.image?
                img(
                  src: url_for(file),
                  alt: file.filename.to_s,
                  class: file_image_classes(is_selected)
                )
              else
                render_file_icon(file)
              end

              button(
                type: "button",
                class: "absolute inset-0 focus:outline-hidden",
                data: {
                  action: "click->file-gallery#selectFile",
                  file_id: file.id,
                  file_url: url_for(file),
                  file_name: file.filename.to_s,
                  file_size: file.byte_size,
                  file_type: file.content_type,
                  file_created: file.created_at.to_s
                }
              ) do
                span(class: "sr-only") { "View details for #{file.filename}" }
              end
            end

            p(class: "pointer-events-none mt-2 block truncate text-sm font-medium text-gray-900 dark:text-white") do
              plain file.filename.to_s
            end
            p(class: "pointer-events-none block text-sm font-medium text-gray-500 dark:text-gray-400") do
              plain number_to_human_size(file.byte_size)
            end
          end
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
          div(class: "flex items-center justify-center h-full") do
            div(class: "text-center") do
              svg(
                class: "mx-auto h-12 w-12 text-gray-400",
                fill: "none",
                viewBox: "0 0 24 24",
                stroke: "currentColor",
                aria: {hidden: "true"}
              ) do
                path(
                  stroke_linecap: "round",
                  stroke_linejoin: "round",
                  d: "M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
                )
              end
              p(class: "mt-1 text-xs text-gray-500 uppercase") { file.content_type&.split("/")&.last || "file" }
            end
          end
        end

        def render_empty_state
          div(class: "text-center py-12 border border-dashed rounded-lg") do
            svg(
              class: "mx-auto h-12 w-12 text-gray-400",
              fill: "none",
              viewBox: "0 0 24 24",
              stroke: "currentColor",
              aria: {hidden: "true"}
            ) do
              path(
                stroke_linecap: "round",
                stroke_linejoin: "round",
                d: "M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
              )
            end
            h3(class: "mt-2 text-sm font-semibold text-gray-900") { "No files" }
            p(class: "mt-1 text-sm text-gray-500") { "Get started by uploading a file." }
          end
        end

        # Helper method to generate URL for ActiveStorage attachment
        def url_for(file)
          if defined?(Rails) && Rails.application.routes.url_helpers.respond_to?(:rails_blob_path)
            Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
          else
            "#"
          end
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
