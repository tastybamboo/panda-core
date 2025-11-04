# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # @label Table
      class TableComponentPreview < ViewComponent::Preview
        # Basic table with sample data
        # @label Default
        def default
          user_struct = Struct.new(:id, :name, :email, :role)
          users = [
            user_struct.new(1, "John Doe", "john@example.com", "Admin"),
            user_struct.new(2, "Jane Smith", "jane@example.com", "Editor"),
            user_struct.new(3, "Bob Johnson", "bob@example.com", "Viewer")
          ]

          render Panda::Core::Admin::TableComponent.new(term: "user", rows: users) do |component|
            component.column("Name") { |user| user.name }
            component.column("Email") { |user| user.email }
            component.column("Role") { |user| user.role }
          end
        end

        # Table with more columns
        # @label Wide Table
        def wide_table
          post_struct = Struct.new(:id, :title, :status, :created_at, :updated_at)
          posts = [
            post_struct.new(1, "First Post", "Published", "2025-01-15", "2025-01-20"),
            post_struct.new(2, "Second Post", "Draft", "2025-01-16", "2025-01-16")
          ]

          render Panda::Core::Admin::TableComponent.new(term: "post", rows: posts) do |component|
            component.column("ID") { |post| post.id }
            component.column("Title") { |post| post.title }
            component.column("Status") { |post| post.status }
            component.column("Created") { |post| post.created_at }
            component.column("Updated") { |post| post.updated_at }
            component.column("Actions") { |post| '<a href="#" class="text-blue-600">Edit</a>'.html_safe }
          end
        end

        # Empty table showing structure
        # @label Empty Table
        def empty
          render Panda::Core::Admin::TableComponent.new(term: "item", rows: []) do |component|
            component.column("Name") { |item| item.name }
            component.column("Description") { |item| item.description }
            component.column("Actions") { |item| '<a href="#" class="text-blue-600">Edit</a>'.html_safe }
          end
        end
      end
    end
  end
end
