# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FormInputComponent do
  describe "initialization and property access" do
    it "accepts name property without NameError" do
      component = described_class.new(name: "email", value: "", placeholder: "")
      expect(component).to be_a(described_class)
    end

    it "accepts value property without NameError" do
      component = described_class.new(name: "email", value: "test@example.com", placeholder: "")
      expect(component).to be_a(described_class)
    end

    it "accepts type property without NameError" do
      component = described_class.new(name: "password", value: "", type: :password, placeholder: "")
      expect(component).to be_a(described_class)
    end

    it "accepts placeholder property without NameError" do
      component = described_class.new(name: "email", value: "", placeholder: "Enter email")
      expect(component).to be_a(described_class)
    end

    it "accepts required property without NameError" do
      component = described_class.new(name: "email", value: "", required: true, placeholder: "")
      expect(component).to be_a(described_class)
    end

    it "accepts disabled property without NameError" do
      component = described_class.new(name: "email", value: "", disabled: true, placeholder: "")
      expect(component).to be_a(described_class)
    end

    it "accepts autocomplete property without NameError" do
      component = described_class.new(name: "email", value: "", autocomplete: "email", placeholder: "")
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering input element" do
    it "renders an input element" do
      component = described_class.new(name: "test", value: "", placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("<input")
    end

    it "sets the input type" do
      component = described_class.new(name: "email", value: "", type: :email, placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include('type="email"')
    end

    it "sets the input name" do
      component = described_class.new(name: "user_email", value: "", placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include('name="user_email"')
    end

    it "sets the input value" do
      component = described_class.new(name: "email", value: "test@example.com", placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include('value="test@example.com"')
    end

    it "sets placeholder text" do
      component = described_class.new(name: "email", value: "", placeholder: "Enter email address")
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include('placeholder="Enter email address"')
    end

    it "does not include value attribute if value is empty" do
      component = described_class.new(name: "email", value: nil, placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      # Should not have value attribute if nil/empty
      expect(html).not_to match(/value="nil"/)
    end
  end

  describe "rendering with required attribute" do
    it "sets required attribute when required: true" do
      component = described_class.new(name: "email", value: "", required: true, placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css('input[required]')
    end

    it "does not set required when required: false" do
      component = described_class.new(name: "email", value: "", required: false, placeholder: "")
      output = Capybara.string(component.call)

      expect(output).not_to have_css('input[required]')
    end
  end

  describe "rendering with disabled state" do
    it "sets disabled attribute when disabled: true" do
      component = described_class.new(name: "email", value: "", disabled: true, placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css('input[disabled]')
    end

    it "applies disabled styling" do
      component = described_class.new(name: "email", value: "", disabled: true, placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css("input.bg-gray-50")
      expect(output).to have_css("input.cursor-not-allowed")
    end

    it "applies enabled styling when not disabled" do
      component = described_class.new(name: "email", value: "", disabled: false, placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css("input.hover\\:cursor-pointer")
    end
  end

  describe "rendering with autocomplete" do
    it "sets autocomplete attribute" do
      component = described_class.new(name: "email", value: "", autocomplete: "email", placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css('input[autocomplete="email"]')
    end

    it "does not set autocomplete if not provided" do
      component = described_class.new(name: "email", value: "", placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      # Should not have autocomplete attribute if not specified
      expect(html).not_to match(/autocomplete="[^"]*"/)
    end
  end

  describe "input ID generation" do
    it "generates ID from name" do
      component = described_class.new(name: "user_email", value: "", placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css('input[id="user_email"]')
    end

    it "sanitizes array notation in ID" do
      component = described_class.new(name: "user[email]", value: "", placeholder: "")
      output = Capybara.string(component.call)
      html = output.native.to_html

      # Should convert brackets to underscores
      expect(html).to include('id="user_email')
    end
  end

  describe "input CSS classes" do
    it "includes base input classes" do
      component = described_class.new(name: "test", value: "", placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css("input.block")
      expect(output).to have_css("input.w-full")
      expect(output).to have_css("input.rounded-md")
    end

    it "includes focus ring classes" do
      component = described_class.new(name: "test", value: "", placeholder: "")
      output = Capybara.string(component.call)

      expect(output).to have_css("input[class*='focus:ring']")
    end
  end

      expect(source).to include("@required")
      expect(source).to include("@disabled")
      expect(source).to include("@autocomplete")
    end
  end
end
