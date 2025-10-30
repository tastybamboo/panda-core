# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TableComponent do
  # Create a simple struct for test data
  let(:user_struct) { Struct.new(:id, :name, :email, :status) }
  let(:users) do
    [
      user_struct.new(1, "Alice Smith", "alice@example.com", "active"),
      user_struct.new(2, "Bob Jones", "bob@example.com", "inactive")
    ]
  end

  describe "rendering with data" do
    it "renders a table with columns and rows" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("Name") { |user| user.name }
        table.column("Email") { |user| user.email }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table.overflow-x-auto")
      expect(output).to have_css("div.table-header-group")
      expect(output).to have_text("Name")
      expect(output).to have_text("Email")
      expect(output).to have_text("Alice Smith")
      expect(output).to have_text("alice@example.com")
      expect(output).to have_text("Bob Jones")
    end

    it "renders correct number of rows" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("Name") { |user| user.name }
      end
      output = Capybara.string(component.call)

      # Count table rows in the body (not header)
      expect(output).to have_css("div.table-row-group div.table-row", count: 2)
    end

    it "applies hover styles to rows" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("Name") { |user| user.name }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table-row.hover\\:bg-gray-500\\/20")
    end

    it "includes data attributes on rows" do
      component = described_class.new(term: "post", rows: users) do |table|
        table.column("Name") { |user| user.name }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table-row[data-post-id='1']")
      expect(output).to have_css("div.table-row[data-post-id='2']")
    end

    it "renders multiple columns" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("ID") { |user| user.id }
        table.column("Name") { |user| user.name }
        table.column("Email") { |user| user.email }
        table.column("Status") { |user| user.status }
      end
      output = Capybara.string(component.call)

      expect(output).to have_text("ID")
      expect(output).to have_text("Name")
      expect(output).to have_text("Email")
      expect(output).to have_text("Status")
    end
  end

  describe "rendering empty state" do
    it "shows empty message when no rows" do
      component = described_class.new(term: "user", rows: []) do |table|
        table.column("Name") { |user| user.name }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h3", text: "No users")
      expect(output).to have_text("Get started by creating a new user")
    end

    it "pluralizes term in empty message" do
      component = described_class.new(term: "page", rows: []) do |table|
        table.column("Title") { |page| page.title }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("h3", text: "No pages")
    end

    it "still renders header when empty" do
      component = described_class.new(term: "post", rows: []) do |table|
        table.column("Title") { |post| post.title }
        table.column("Author") { |post| post.author }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table-header-group")
      expect(output).to have_text("Title")
      expect(output).to have_text("Author")
    end
  end

  describe "header styling" do
    it "applies rounded corners to first and last header cells" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("First") { |u| u.name }
        table.column("Middle") { |u| u.email }
        table.column("Last") { |u| u.status }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table-cell.rounded-tl-md")
      expect(output).to have_css("div.table-cell.rounded-tr-md")
    end

    it "applies header background color" do
      component = described_class.new(term: "user", rows: users) do |table|
        table.column("Name") { |u| u.name }
      end
      output = Capybara.string(component.call)

      expect(output).to have_css("div.table-row.bg-dark")
    end
  end
end
