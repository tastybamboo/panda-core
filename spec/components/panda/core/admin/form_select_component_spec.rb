# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FormSelectComponent, type: :component do
  describe "initialization and property access" do
    it "accepts name property without NameError" do
      component = described_class.new(name: "status", options: [], prompt: "Select")
      expect(component).to be_a(described_class)
    end

    it "accepts options property without NameError" do
      options = [["Active", "active"], ["Inactive", "inactive"]]
      component = described_class.new(name: "status", options: options, prompt: "Select")
      expect(component).to be_a(described_class)
    end

    it "accepts prompt property without NameError" do
      component = described_class.new(name: "status", options: [], prompt: "Choose one")
      expect(component).to be_a(described_class)
    end

    it "accepts required property without NameError" do
      component = described_class.new(name: "status", options: [], prompt: "Select", required: true)
      expect(component).to be_a(described_class)
    end

    it "accepts disabled property without NameError" do
      component = described_class.new(name: "status", options: [], prompt: "Select", disabled: true)
      expect(component).to be_a(described_class)
    end

    it "accepts include_blank property without NameError" do
      component = described_class.new(name: "status", options: [], prompt: "Select", include_blank: true)
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering select element" do
    it "renders a select element" do
      component = described_class.new(name: "status", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("<select")
    end

    it "sets the select name" do
      component = described_class.new(name: "user_status", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include('name="user_status"')
    end

    it "generates ID from name" do
      component = described_class.new(name: "user_status", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include('id="user_status"')
    end

    it "sanitizes array notation in ID" do
      component = described_class.new(name: "user[status]", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      # Should convert brackets to underscores
      expect(html).to include('id="user_status')
    end
  end

  describe "rendering with required attribute" do
    it "sets required attribute when required: true" do
      component = described_class.new(name: "status", options: [], prompt: "Select", required: true)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("required")
    end

    it "does not set required when required: false" do
      component = described_class.new(name: "status", options: [], prompt: "Select", required: false)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).not_to match(/\srequired\s/)
    end
  end

  describe "rendering with disabled state" do
    it "sets disabled attribute when disabled: true" do
      component = described_class.new(name: "status", options: [], prompt: "Select", disabled: true)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("disabled")
    end

    it "applies disabled styling" do
      component = described_class.new(name: "status", options: [], prompt: "Select", disabled: true)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("bg-gray-50")
      expect(html).to include("cursor-not-allowed")
    end

    it "applies enabled styling when not disabled" do
      component = described_class.new(name: "status", options: [], prompt: "Select", disabled: false)
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("hover:cursor-pointer")
    end
  end

  describe "select CSS classes" do
    it "includes base select classes" do
      component = described_class.new(name: "status", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("block")
      expect(html).to include("w-full")
      expect(html).to include("rounded-md")
    end

    it "includes focus ring classes" do
      component = described_class.new(name: "status", options: [], prompt: "Select")
      output = Capybara.string(render_inline(component).to_html)
      html = output.native.to_html

      expect(html).to include("focus:ring")
    end
  end
end
