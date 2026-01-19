# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FormErrorComponent do
  describe "initialization and property access" do
    it "accepts model property without NameError" do
      user = instance_double("User")
      component = described_class.new(model: user)
      expect(component).to be_a(described_class)
    end

    it "accepts model with no errors" do
      user = instance_double("User", errors: double(full_messages: []))
      component = described_class.new(model: user)
      expect(component).to be_a(described_class)
    end

    it "accepts model with errors" do
      errors = instance_double(full_messages: ["Email can't be blank"])
      user = instance_double("User", errors: errors)
      component = described_class.new(model: user)
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering with no errors" do
    it "does not render when model has no errors" do
      user = instance_double("User", errors: double(full_messages: []))
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)

      expect(output.native.to_html.strip).to be_empty
    end
  end

  describe "rendering with ActiveModel errors" do
    it "renders error container when model has errors" do
      errors = double(full_messages: ["Email can't be blank"])
      user = double("User", errors: errors)
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("bg-red-50")
      expect(html).to include("border-red-200")
    end

    it "displays error messages" do
      errors = double(full_messages: ["Email can't be blank", "Password too short"])
      user = double("User", errors: errors)
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("Email can't be blank")
      expect(output).to have_text("Password too short")
    end

    it "applies correct styling classes" do
      errors = double(full_messages: ["Error message"])
      user = double("User", errors: errors)
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("mb-4")
      expect(html).to include("p-4")
      expect(html).to include("rounded-md")
    end
  end

  describe "rendering with nil model" do
    it "does not render when model is nil" do
      component = described_class.new(model: nil)
      output = Capybara.string(render_inline(component).to_html)

      expect(output.native.to_html.strip).to be_empty
    end
  end

  describe "rendering with array of errors" do
    # Note: This component primarily uses ActiveModel errors
    # but may handle array errors in some configurations
    it "handles model without errors method gracefully" do
      model = Object.new
      component = described_class.new(model: model)
      expect(component).to be_a(described_class)
    end
  end

  describe "default_attrs" do
    it "provides correct default attributes" do
      errors = instance_double(full_messages: ["Error"])
      user = instance_double("User", errors: errors)
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div[class*='bg-red-50']")
      expect(output).to have_css("div[class*='border']")
      expect(output).to have_css("div[class*='rounded-md']")
    end
  end

  describe "error message formatting" do
    it "displays full error messages" do
      errors = instance_double(
        full_messages: [
          "User name can't be blank",
          "User email is invalid"
        ]
      )
      user = instance_double("User", errors: errors)
      component = described_class.new(model: user)
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_text("User name can't be blank")
      expect(output).to have_text("User email is invalid")
    end
  end
end
