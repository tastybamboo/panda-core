# frozen_string_literal: true

module Panda
  module Core
    class FormBuilder < ActionView::Helpers::FormBuilder
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper

      def label(attribute, text = nil, options = {})
        super(attribute, text, options.reverse_merge(class: label_styles))
      end

      def text_field(attribute, options = {})
        # Extract custom label if provided
        custom_label = options.delete(:label)

        # Add disabled/readonly styling
        field_classes = if options[:readonly] || options[:disabled]
          readonly_input_styles
        else
          input_styles
        end

        if options.dig(:data, :prefix)
          content_tag :div, class: container_styles do
            label(attribute, custom_label) + meta_text(options) +
              content_tag(:div, class: "flex flex-grow") do
                content_tag(:span,
                  class: "inline-flex items-center px-3 text-base border border-r-none rounded-s-md whitespace-nowrap break-keep") do
                  options.dig(:data, :prefix)
                end +
                  super(attribute, options.reverse_merge(class: "#{field_classes} input-prefix rounded-l-none border-l-none"))
              end + error_message(attribute)
          end
        else
          content_tag :div, class: container_styles do
            label(attribute, custom_label) + meta_text(options) + super(attribute, options.reverse_merge(class: field_classes)) + error_message(attribute)
          end
        end
      end

      def email_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def datetime_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def text_area(method, options = {})
        # Extract custom label if provided
        custom_label = options.delete(:label)

        content_tag :div, class: container_styles do
          label(method, custom_label) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def password_field(attribute, options = {})
        content_tag :div, class: container_styles do
          label(attribute) + meta_text(options) + super(attribute, options.reverse_merge(class: input_styles)) + error_message(attribute)
        end
      end

      def select(method, choices = nil, options = {}, html_options = {})
        # Extract custom label if provided
        custom_label = options.delete(:label)

        content_tag :div, class: container_styles do
          label(method, custom_label) + meta_text(options) + super(method, choices, options, html_options.reverse_merge(class: select_styles)) + select_svg + error_message(method)
        end
      end

      def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, collection, value_method, text_method, options, html_options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        wrap_field(method, options) do
          super(
            method,
            priority_zones,
            options,
            html_options.reverse_merge(class: select_styles)
          )
        end
      end

      def file_field(method, options = {})
        # Extract custom label if provided
        custom_label = options.delete(:label)

        # Check if cropper is requested
        with_cropper = options.delete(:with_cropper)

        # Check if simple mode is requested (no fancy upload UI)
        simple_mode = options.delete(:simple)

        if with_cropper
          # Image upload with cropper
          aspect_ratio = options.delete(:aspect_ratio) # e.g., 1.91 for OG images (1200x630)
          min_width = options.delete(:min_width) || 0
          min_height = options.delete(:min_height) || 0
          accept_types = options.delete(:accept) || "image/*"
          field_id = "#{object_name}_#{method}"

          content_tag :div, class: container_styles do
            label(method, custom_label) +
              meta_text(options) +
              # Cropper stylesheet
              @template.content_tag(:link, nil, rel: "stylesheet", href: "https://cdn.jsdelivr.net/npm/cropperjs@1.6.2/dist/cropper.min.css") +
              # File input
              content_tag(:div, class: "mt-2") do
                super(method, options.reverse_merge(
                  id: field_id,
                  accept: accept_types,
                  class: "file:rounded file:border-0 file:text-sm file:bg-white file:text-gray-500 hover:file:bg-gray-50 bg-white px-2.5 hover:bg-gray-50 #{input_styles}",
                  data: {
                    controller: "image-cropper",
                    image_cropper_target: "input",
                    action: "change->image-cropper#handleFileSelect",
                    image_cropper_aspect_ratio_value: aspect_ratio,
                    image_cropper_min_width_value: min_width,
                    image_cropper_min_height_value: min_height
                  }
                ))
              end +
              # Cropper container (hidden by default)
              content_tag(:div, class: "hidden mt-4 bg-gray-100 dark:bg-gray-800 p-4 rounded-lg", data: {image_cropper_target: "cropperContainer"}) do
                # Preview image
                @template.image_tag("", alt: "Crop preview", data: {image_cropper_target: "preview"}, class: "max-w-full") +
                  # Cropper controls
                  content_tag(:div, class: "mt-4 flex gap-2 flex-wrap") do
                    @template.button_tag("Crop & Save", type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500", data: {action: "click->image-cropper#crop"}) +
                      @template.button_tag("Cancel", type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#cancel"}) +
                      @template.button_tag(type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#reset"}) do
                        @template.content_tag(:i, "", class: "fa-solid fa-rotate-left") +
                          @template.content_tag(:span, "Reset")
                      end +
                      @template.button_tag(type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#rotate", degrees: "90"}) do
                        @template.content_tag(:i, "", class: "fa-solid fa-rotate-right") +
                          @template.content_tag(:span, "Rotate")
                      end +
                      @template.button_tag(type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#flip", direction: "horizontal"}) do
                        @template.content_tag(:i, "", class: "fa-solid fa-arrows-left-right") +
                          @template.content_tag(:span, "Flip H")
                      end +
                      @template.button_tag(type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#zoom", ratio: "0.1"}) do
                        @template.content_tag(:i, "", class: "fa-solid fa-magnifying-glass-plus") +
                          @template.content_tag(:span, "Zoom In")
                      end +
                      @template.button_tag(type: "button", class: "inline-flex items-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring inset-ring-gray-300 hover:bg-gray-50", data: {action: "click->image-cropper#zoom", ratio: "-0.1"}) do
                        @template.content_tag(:i, "", class: "fa-solid fa-magnifying-glass-minus") +
                          @template.content_tag(:span, "Zoom Out")
                      end
                  end
              end
          end
        elsif simple_mode
          # Simple file input with basic styling
          content_tag :div, class: container_styles do
            label(method, custom_label) +
              meta_text(options) +
              super(method, options.reverse_merge(class: "file:rounded file:border-0 file:text-sm file:bg-white file:text-gray-500 hover:file:bg-gray-50 bg-white px-2.5 hover:bg-gray-50 #{input_styles}"))
          end
        else
          # Fancy drag-and-drop UI
          accept_types = options.delete(:accept) || "image/*"
          max_size = options.delete(:max_size) || "10MB"
          file_types_display = options.delete(:file_types_display) || "PNG, JPG, GIF"

          field_id = "#{object_name}_#{method}"

          content_tag :div, class: "#{container_styles} col-span-full", data: {controller: "file-upload"} do
            label(method, custom_label) +
              meta_text(options) +
              content_tag(:div, class: "mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10 dark:border-white/25 transition-colors", data: {file_upload_target: "dropzone"}) do
                content_tag(:div, class: "text-center") do
                  # Icon
                  @template.content_tag(:svg, viewBox: "0 0 24 24", fill: "currentColor", "data-slot": "icon", "aria-hidden": true, class: "mx-auto size-12 text-gray-300 dark:text-gray-600") do
                    @template.content_tag(:path, nil, d: "M1.5 6a2.25 2.25 0 0 1 2.25-2.25h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6ZM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0 0 21 18v-1.94l-2.69-2.689a1.5 1.5 0 0 0-2.12 0l-.88.879.97.97a.75.75 0 1 1-1.06 1.06l-5.16-5.159a1.5 1.5 0 0 0-2.12 0L3 16.061Zm10.125-7.81a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Z", "clip-rule": "evenodd", "fill-rule": "evenodd")
                  end +
                    # Upload area
                    content_tag(:div, class: "mt-4 flex items-baseline justify-center text-sm leading-6 text-gray-600 dark:text-gray-400") do
                      content_tag(:label, for: field_id, class: "relative cursor-pointer rounded-md bg-transparent font-semibold text-indigo-600 focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-indigo-600 hover:text-indigo-500 dark:text-indigo-400 dark:focus-within:outline-indigo-500 dark:hover:text-indigo-300") do
                        content_tag(:span, "Upload a file") +
                          super(method, options.reverse_merge(
                            id: field_id,
                            accept: accept_types,
                            class: "sr-only",
                            data: {
                              file_upload_target: "input",
                              action: "change->file-upload#handleFileSelect"
                            }
                          ))
                      end +
                        content_tag(:span, "or drag and drop", class: "pl-1")
                    end +
                    # File type info
                    content_tag(:p, "#{file_types_display} up to #{max_size}", class: "text-xs/5 text-gray-600 dark:text-gray-400")
                end
              end +
              # File info display (hidden by default)
              content_tag(:div, "", class: "hidden mt-3", data: {file_upload_target: "fileInfo"}) +
              # Preview display (hidden by default)
              content_tag(:div, "", class: "hidden mt-3", data: {file_upload_target: "preview"})
          end
        end
      end

      def button(value = nil, options = {}, &block)
        value ||= submit_default_value
        options = options.dup

        # Handle formmethod specially
        if options[:formmethod] == "delete"
          options[:name] = "_method"
          options[:value] = "delete"
        end

        base_classes = [
          "inline-flex items-center rounded-md",
          "px-3 py-2",
          "text-base font-semibold",
          "shadow-sm"
        ]

        # Only add fa-circle-check for non-block buttons
        base_classes << "fa-circle-check" unless block_given?

        options[:class] = [
          *base_classes,
          options[:class]
        ].compact.join(" ")

        if block_given?
          @template.button_tag(options, &block)
        else
          @template.button_tag(value, options)
        end
      end

      def submit(value = nil, options = {})
        value ||= submit_default_value

        # Use the primary mid color for save/create actions
        action = object.persisted? ? :save : :create
        button_classes = case action
        when :save, :create
          "text-white bg-mid hover:bg-mid/80"
        when :save_inactive
          "text-white bg-gray-400"
        when :secondary
          "text-gray-700 border-2 border-gray-500 bg-transparent hover:bg-gray-100 transition-all"
        else
          "text-gray-700 border-2 border-gray-500 bg-transparent hover:bg-gray-100 transition-all"
        end

        # Combine with common button classes
        classes = "inline-flex items-center rounded-md font-medium shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 px-3 py-2 #{button_classes}"

        options[:class] = options[:class] ? "#{options[:class]} #{classes}" : classes

        super
      end

      def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: "border-gray-300 ml-2"), checked_value, unchecked_value)
        end
      end

      def date_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles))
        end
      end

      def radio_button_group(method, choices, options = {})
        current_value = object.send(method)

        content_tag :div, class: container_styles do
          label(method) +
            meta_text(options) +
            content_tag(:div, class: "mt-2 space-y-2") do
              choices.map do |choice|
                choice_value = choice.is_a?(Array) ? choice.last : choice
                choice_label = choice.is_a?(Array) ? choice.first : choice.to_s.humanize
                choice_id = "#{object_name}_#{method}_#{choice_value}"
                is_checked = (current_value.to_s == choice_value.to_s)

                content_tag(:label, class: "flex items-center gap-x-3 rounded-lg border border-gray-300 px-3 py-3 text-sm/6 font-medium cursor-pointer hover:bg-gray-50 dark:border-white/10 dark:hover:bg-white/5") do
                  radio_button(method, choice_value, {id: choice_id, checked: is_checked, class: "size-4 border-gray-300 text-indigo-600 focus:ring-indigo-600 dark:border-white/10 dark:bg-white/5"}) +
                    content_tag(:span, choice_label, class: "text-gray-900 dark:text-white")
                end
              end.join.html_safe
            end
        end
      end

      def meta_text(options)
        return unless options[:meta]

        @template.content_tag(:p, options[:meta], class: "block text-black/60 text-sm mb-2")
      end

      def section_heading(text, options = {})
        @template.content_tag(:div, class: "-mx-4 sm:-mx-6 px-4 sm:px-6 py-4 bg-gray-200 dark:bg-gray-700 mb-6") do
          @template.content_tag(:h3, text, class: "text-base font-semibold text-gray-900 dark:text-white")
        end
      end

      private

      def label_styles
        "block text-sm/6 font-medium text-gray-900 dark:text-gray-100"
      end

      def base_input_styles
        "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-indigo-600 sm:text-sm/6 dark:bg-white/5 dark:text-white dark:outline-white/10 dark:placeholder:text-gray-500 dark:focus:outline-indigo-500"
      end

      def input_styles
        base_input_styles
      end

      def readonly_input_styles
        "block w-full rounded-md bg-gray-50 px-3 py-1.5 text-base text-gray-500 outline-1 -outline-offset-1 outline-gray-200 cursor-not-allowed sm:text-sm/6 dark:bg-white/10 dark:text-gray-500 dark:outline-white/5"
      end

      def input_styles_prefix
        "#{input_styles} prefix"
      end

      def select_styles
        "block w-full rounded-md bg-white px-3 py-1.5 pr-8 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 appearance-none focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-indigo-600 sm:text-sm/6 dark:bg-white/5 dark:text-white dark:outline-white/10 dark:focus:outline-indigo-500"
      end

      def select_svg
        @template.content_tag(:svg,
          class: "pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-gray-400", aria_hidden: true) do
          @template.content_tag(:path, d: "M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z")
        end
      end

      def button_styles
        "inline-flex items-center rounded-md font-medium shadow-sm focus-visible:outline focus-visible:outline-0 focus-visible:outline-offset-none text-gray-700 border-2 border-gray-500 bg-transparent hover:bg-gray-100 transition-all gap-x-1.5 px-3 py-2 text-base gap-x-1.5 px-2.5 py-1.5 mt-2 "
      end

      def container_styles
        "panda-core-field-container mb-4"
      end

      def textarea_styles
        "#{input_styles} min-h-32"
      end

      def submit_default_value
        object.persisted? ? "Update #{object.class.name.demodulize}" : "Create #{object.class.name.demodulize}"
      end

      def wrap_field(method, options = {}, &block)
        @template.content_tag(:div, class: "panda-core-field-container") do
          label(method, class: "font-light inline-block mb-1 text-base leading-6") +
            meta_text(options) +
            @template.content_tag(:div, class: field_wrapper_styles, &block)
        end
      end

      def field_wrapper_styles
        "mt-1"
      end

      def error_message(attribute)
        return unless object.respond_to?(:errors) && object.errors[attribute]&.any?

        content_tag(:p, class: "mt-2 text-sm text-red-600") do
          object.errors[attribute].join(", ")
        end
      end
    end
  end
end
