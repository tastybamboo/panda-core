# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Form Select
      # @tags stable
      class FormSelectComponentPreview < ViewComponent::Preview
        # Basic select dropdown
        # @label Basic Select
        def basic_select
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "user[role]",
            options: [
              ["Administrator", "admin"],
              ["Editor", "editor"],
              ["Viewer", "viewer"]
            ]
          )
        end

        # Select with a value selected
        # @label With Selected Value
        def with_selected
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "post[status]",
            options: [
              ["Active", "active"],
              ["Draft", "draft"],
              ["Hidden", "hidden"],
              ["Archived", "archived"]
            ],
            selected: "draft"
          )
        end

        # Select with prompt text
        # @label With Prompt
        def with_prompt
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "post[author_id]",
            options: [
              ["Alice Smith", 1],
              ["Bob Jones", 2],
              ["Carol Williams", 3]
            ],
            prompt: "Select an author..."
          )
        end

        # Select with include_blank option
        # @label With Blank Option
        def with_blank
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "post[category]",
            options: [
              ["Technology", "tech"],
              ["Health", "health"],
              ["Business", "business"]
            ],
            include_blank: true
          )
        end

        # Required select field
        # @label Required Field
        def required_field
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "user[country]",
            options: [
              ["United States", "US"],
              ["United Kingdom", "GB"],
              ["Canada", "CA"]
            ],
            prompt: "Select a country...",
            required: true
          )
        end

        # Disabled select field
        # @label Disabled Field
        def disabled_field
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "user[status]",
            options: [
              ["Active", "active"],
              ["Inactive", "inactive"]
            ],
            selected: "active",
            disabled: true
          )
        end

        # Select with numeric IDs
        # @label Numeric IDs
        def numeric_ids
          render Panda::Core::Admin::FormSelectComponent.new(
            name: "post[author_id]",
            options: [
              ["Alice Smith", 1],
              ["Bob Jones", 2],
              ["Carol Williams", 3]
            ],
            selected: 2
          )
        end
      end
    end
  end
end
