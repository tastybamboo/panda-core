# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Lightweight callout for inline notices (info, warning, success, error).
      # Intended for static, in-form guidance (not toast/flash).
      class CalloutComponent < Panda::Core::Base
        def initialize(text: nil, title: nil, kind: :info, icon: nil, **attrs)
          @text = text
          @title = title
          @kind = kind
          @icon = icon
          super(**attrs)
        end

        attr_reader :text, :title, :kind, :icon

        def default_attrs
          {
            class: "rounded-2xl border px-4 py-3 text-sm #{tone_classes}"
          }
        end

        def icon_class
          icon || default_icon
        end

        def default_icon
          case kind
          when :success
            "fa-circle-check"
          when :warning
            "fa-triangle-exclamation"
          when :error, :alert
            "fa-circle-xmark"
          else
            "fa-circle-info"
          end
        end

        def tone_classes
          case kind
          when :success
            "bg-emerald-50 text-emerald-700 border-emerald-200"
          when :warning
            "bg-amber-50 text-amber-700 border-amber-200"
          when :error, :alert
            "bg-rose-50 text-rose-700 border-rose-200"
          else
            "bg-gray-50 text-gray-700 border-gray-200"
          end
        end
      end
    end
  end
end
