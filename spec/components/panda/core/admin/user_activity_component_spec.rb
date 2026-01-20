# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::UserActivityComponent, type: :component do
  let(:user_class) do
    Class.new do
      def self.name
        "Panda::Core::User"
      end

      attr_accessor :name, :email, :_avatar_url

      def initialize(name:, email:, avatar_url: nil)
        @name = name
        @email = email
        @_avatar_url = avatar_url
      end

      def avatar_url(size: nil)
        @_avatar_url
      end

      def image_url
        @_avatar_url
      end
    end
  end

  let(:user) { user_class.new(name: "Alice Smith", email: "alice@example.com") }
  let(:time) { 2.hours.ago }

  before do
    stub_const("Panda::Core::User", user_class)
  end

  describe "rendering" do
    it "renders user and time when both present" do
      component = described_class.new(user: user, at: time)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Alice Smith")
      expect(output).to have_text("ago")
    end

    it "renders user without time" do
      component = described_class.new(user: user)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Alice Smith")
      expect(output).to have_text("Not published")
    end

    it "renders only time without user" do
      component = described_class.new(at: time)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("ago")
      expect(output).to have_css("div.text-black\\/60")
    end

    it "does not render when neither user nor time present" do
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output.text.strip).to be_empty
    end

    it "handles invalid time value" do
      component = described_class.new(user: user, at: "invalid")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Not published")
    end
  end
end
