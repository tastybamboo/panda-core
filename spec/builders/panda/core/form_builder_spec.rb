# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::FormBuilder, type: :helper do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:user) { Panda::Core::User.new(name: "John Doe", email: "john@example.com") }
  let(:builder) { described_class.new(:user, user, template, {}) }

  describe "#text_field with custom label" do
    it "renders the custom label text when label option is provided" do
      result = builder.text_field(:name, label: "Full Name")

      expect(result).to include("Full Name")
      expect(result).to include('name="user[name]"')
    end

    it "uses the default label when no custom label is provided" do
      result = builder.text_field(:name)

      expect(result).to include("Name")
      expect(result).to include('name="user[name]"')
    end

    it "removes the label option from the input attributes" do
      result = builder.text_field(:name, label: "Full Name", placeholder: "Enter name")

      # Should not pass label as an HTML attribute to the input
      expect(result).not_to include('label="Full Name"')
      expect(result).to include('placeholder="Enter name"')
    end

    it "works with data attributes and custom label" do
      result = builder.text_field(:name,
        label: "User Name",
        data: {controller: "test", action: "test#action"})

      expect(result).to include("User Name")
      expect(result).to include('data-controller="test"')
      expect(result).to include('data-action="test#action"')
    end

    it "works with prefix data attribute and custom label" do
      result = builder.text_field(:name,
        label: "Display Name",
        data: {prefix: "@"})

      expect(result).to include("Display Name")
      expect(result).to include("@")
    end
  end

  describe "#text_area with custom label" do
    it "renders the custom label text when label option is provided" do
      result = builder.text_area(:oauth_avatar_url, label: "Avatar URL")

      expect(result).to include("Avatar URL")
      expect(result).to include('name="user[oauth_avatar_url]"')
    end

    it "uses the default label when no custom label is provided" do
      result = builder.text_area(:oauth_avatar_url)

      expect(result).to include("Oauth avatar url")
      expect(result).to include('name="user[oauth_avatar_url]"')
    end

    it "removes the label option from the textarea attributes" do
      result = builder.text_area(:oauth_avatar_url, label: "Profile Image URL", rows: 5)

      expect(result).not_to include('label="Profile Image URL"')
      expect(result).to include('rows="5"')
    end

    it "works with meta text and custom label" do
      result = builder.text_area(:oauth_avatar_url,
        label: "OAuth Avatar",
        meta: "Enter the OAuth avatar URL")

      expect(result).to include("OAuth Avatar")
      expect(result).to include("Enter the OAuth avatar URL")
    end
  end

  describe "#select with custom label" do
    let(:choices) { [["Dark", "dark"], ["Light", "light"]] }

    it "renders the custom label text when label option is provided" do
      result = builder.select(:current_theme, choices, {label: "Color Theme"})

      expect(result).to include("Color Theme")
      expect(result).to include('name="user[current_theme]"')
    end

    it "uses the default label when no custom label is provided" do
      result = builder.select(:current_theme, choices)

      expect(result).to include("Current theme")
      expect(result).to include('name="user[current_theme]"')
    end

    it "removes the label option from the select attributes" do
      result = builder.select(:current_theme, choices, {label: "Theme Preference"})

      expect(result).not_to include('label="Theme Preference"')
    end

    it "works with meta text and custom label" do
      result = builder.select(:current_theme, choices,
        label: "Theme Selection",
        meta: "Pick your preferred theme")

      expect(result).to include("Theme Selection")
      expect(result).to include("Pick your preferred theme")
    end
  end

  describe "#file_field with custom label" do
    context "with simple mode" do
      it "renders the custom label text when label option is provided" do
        result = builder.file_field(:avatar, label: "Profile Picture", simple: true)

        expect(result).to include("Profile Picture")
        expect(result).to include('name="user[avatar]"')
      end

      it "uses the default label when no custom label is provided" do
        result = builder.file_field(:avatar, simple: true)

        expect(result).to include("Avatar")
        expect(result).to include('name="user[avatar]"')
      end
    end

    context "with cropper mode" do
      it "renders the custom label text when label option is provided" do
        result = builder.file_field(:avatar,
          label: "Upload Photo",
          with_cropper: true,
          aspect_ratio: 1.0)

        expect(result).to include("Upload Photo")
        expect(result).to include('data-controller="image-cropper"')
      end

      it "uses the default label when no custom label is provided" do
        result = builder.file_field(:avatar, with_cropper: true)

        expect(result).to include("Avatar")
        expect(result).to include('data-controller="image-cropper"')
      end

      it "removes the label option from the file input attributes" do
        result = builder.file_field(:avatar,
          label: "Image Upload",
          with_cropper: true,
          aspect_ratio: 1.91)

        expect(result).not_to include('label="Image Upload"')
        expect(result).to include('data-image-cropper-aspect-ratio-value="1.91"')
      end
    end

    context "with drag-and-drop mode (default)" do
      it "renders the custom label text when label option is provided" do
        result = builder.file_field(:avatar, label: "Choose File")

        expect(result).to include("Choose File")
        expect(result).to include('data-controller="file-upload"')
      end

      it "uses the default label when no custom label is provided" do
        result = builder.file_field(:avatar)

        expect(result).to include("Avatar")
        expect(result).to include('data-controller="file-upload"')
      end
    end
  end

  describe "#number_field with custom label" do
    it "renders the custom label text when label option is provided" do
      result = builder.number_field(:id, label: "User ID")

      expect(result).to include("User ID")
      expect(result).to include('name="user[id]"')
    end

    it "uses the default label when no custom label is provided" do
      result = builder.number_field(:id)

      expect(result).to include("Id")
      expect(result).to include('name="user[id]"')
    end

    it "removes the label option from the input attributes" do
      result = builder.number_field(:id, label: "User ID", min: 1)

      expect(result).not_to include('label="User ID"')
      expect(result).to include('min="1"')
    end

    it "wraps in a container with proper styling" do
      result = builder.number_field(:id)

      expect(result).to include("panda-core-field-container")
    end
  end

  describe "integration: multiple fields with custom labels" do
    it "handles different field types with custom labels in the same form" do
      text_result = builder.text_field(:name, label: "Full Name")
      textarea_result = builder.text_area(:oauth_avatar_url, label: "Avatar URL")
      select_result = builder.select(:current_theme, [["Dark", "dark"]], {label: "Theme"})

      expect(text_result).to include("Full Name")
      expect(textarea_result).to include("Avatar URL")
      expect(select_result).to include("Theme")

      # Ensure each field retains its correct name attribute
      expect(text_result).to include('name="user[name]"')
      expect(textarea_result).to include('name="user[oauth_avatar_url]"')
      expect(select_result).to include('name="user[current_theme]"')
    end
  end

  describe "#submit" do
    context "with a model object" do
      it "renders a submit button with create text for new records" do
        result = builder.submit
        expect(result).to include("Create User")
      end

      it "renders a submit button with the given value" do
        result = builder.submit("Save Changes")
        expect(result).to include("Save Changes")
      end
    end

    context "without a model object (form_with url:)" do
      let(:nil_builder) { described_class.new(nil, nil, template, {}) }

      it "renders a submit button without raising an error" do
        result = nil_builder.submit("Create Token")
        expect(result).to include("Create Token")
      end

      it "uses 'Submit' as the default value when no value is given" do
        result = nil_builder.submit
        expect(result).to include("Submit")
      end
    end
  end

  describe "#button" do
    context "without a model object (form_with url:)" do
      let(:nil_builder) { described_class.new(nil, nil, template, {}) }

      it "renders a button without raising an error" do
        result = nil_builder.button("Create Token")
        expect(result).to include("Create Token")
      end

      it "uses 'Submit' as the default value when no value is given" do
        result = nil_builder.button
        expect(result).to include("Submit")
      end
    end
  end

  describe "backward compatibility" do
    it "does not break existing forms without custom labels" do
      text_result = builder.text_field(:name)
      textarea_result = builder.text_area(:oauth_avatar_url)
      select_result = builder.select(:email, [["test@example.com", "test@example.com"]])

      # Should all render without errors
      expect(text_result).to be_present
      expect(textarea_result).to be_present
      expect(select_result).to be_present

      # Should use humanized attribute names
      expect(text_result).to include("Name")
      expect(textarea_result).to include("Oauth avatar url")
      expect(select_result).to include("Email")
    end
  end
end
