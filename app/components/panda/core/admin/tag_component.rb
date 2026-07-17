# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class TagComponent < Panda::Core::Base
        def initialize(text: nil, page_type: nil, status: :active, **attrs)
          @status = status
          @text = text
          @page_type = page_type
          super(**attrs)
        end

        attr_reader :status, :text, :page_type

        def computed_text
          if @page_type
            @text || type_display_text
          else
            @text || @status.to_s.humanize
          end
        end

        def type_display_text
          case @page_type
          when :standard
            "Active"
          when :hidden_type
            "Hidden"
          else
            @page_type.to_s.humanize
          end
        end

        # Badge colours are themeable via the --panda-badge-{success,error,
        # warning,info,neutral}-{bg,fg} tokens (see
        # app/assets/tailwind/application.css). Each helper below returns an
        # arbitrary-value Tailwind utility pair whose var() fallback resolves
        # to exactly today's literal emerald/amber/sky/rose/gray-100
        # utility classes, so this is a no-op unless a host app sets
        # data-theme.
        def tag_classes
          base = "inline-flex items-center px-2.5 py-0.5 text-xs font-medium rounded-full "
          base + (@page_type ? type_classes : status_classes)
        end

        def type_classes
          case @page_type
          when :system
            badge_classes(:error)
          when :posts
            badge_classes(:info)
          when :code
            badge_classes(:info)
          when :standard
            badge_classes(:success)
          when :hidden_type
            badge_classes(:neutral)
          else
            badge_classes(:neutral)
          end
        end

        def status_classes
          case @status
          when :active
            badge_classes(:success)
          when :live
            badge_classes(:success)
          when :draft
            badge_classes(:warning)
          when :inactive, :hidden
            badge_classes(:neutral)
          when :auto
            badge_classes(:info)
          when :warning
            badge_classes(:error)
          when :static
            badge_classes(:neutral)
          else
            badge_classes(:neutral)
          end
        end

        private

        # Tailwind's content scanner extracts candidate class names by
        # scanning raw source text — it does not evaluate Ruby, so every
        # arbitrary-value class must appear as a complete literal string
        # somewhere in this file (interpolating the tone into the class name
        # would produce unscannable text like "bg-[var(--panda-badge-#{tone}
        # -bg...)]" and silently generate no CSS).
        BADGE_CLASSES = {
          success: "text-[var(--panda-badge-success-fg,var(--color-emerald-600))] bg-[var(--panda-badge-success-bg,var(--color-emerald-50))]",
          warning: "text-[var(--panda-badge-warning-fg,var(--color-amber-600))] bg-[var(--panda-badge-warning-bg,var(--color-amber-50))]",
          info: "text-[var(--panda-badge-info-fg,var(--color-sky-600))] bg-[var(--panda-badge-info-bg,var(--color-sky-50))]",
          error: "text-[var(--panda-badge-error-fg,var(--color-rose-600))] bg-[var(--panda-badge-error-bg,var(--color-rose-50))]",
          neutral: "text-[var(--panda-badge-neutral-fg,var(--color-gray-600))] bg-[var(--panda-badge-neutral-bg,var(--color-gray-100))]"
        }.freeze
        private_constant :BADGE_CLASSES

        def badge_classes(tone)
          BADGE_CLASSES.fetch(tone)
        end
      end
    end
  end
end
