# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::UserDisplayComponent do
  let(:user_struct) do
    Struct.new(:firstname, :lastname, :email, :image_url) do
      def name
        "#{firstname} #{lastname}"
      end
    end
  end

  let(:user_with_avatar) do
    user_struct.new("Alice", "Smith", "alice@example.com", "https://example.com/avatar.jpg")
  end

  let(:user_without_avatar) do
    user_struct.new("Bob", "Jones", "bob@example.com", nil)
  end

  describe "rendering" do
    it "renders user name and email" do
      component = described_class.new(user: user_with_avatar)
      output = Capybara.string(component.call)

      expect(output).to have_text("Alice Smith")
      expect(output).to have_text("alice@example.com")
    end

    it "renders avatar image when available" do
      component = described_class.new(user: user_with_avatar)
      output = Capybara.string(component.call)

      expect(output).to have_css("img[src='https://example.com/avatar.jpg']")
    end

    it "renders initials when no avatar" do
      component = described_class.new(user: user_without_avatar)
      output = Capybara.string(component.call)

      expect(output).to have_css("span", text: "BJ")
    end

    it "applies circular styling to avatar" do
      component = described_class.new(user: user_with_avatar)
      output = Capybara.string(component.call)

      expect(output).to have_css("img.rounded-full")
    end

    it "renders email in muted color" do
      component = described_class.new(user: user_with_avatar)
      output = Capybara.string(component.call)

      expect(output).to have_css(".text-gray-500", text: "alice@example.com")
    end
  end
end
