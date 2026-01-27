# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FormFooterComponent, type: :component do
  describe "rendering" do
    it "renders a submit button with default text" do
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_button("Save")
    end

    it "renders with custom submit text" do
      component = described_class.new(submit_text: "Create Page")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_button("Create Page")
    end

    it "renders with explicit icon" do
      component = described_class.new(submit_text: "Save", icon: "fa-save")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("i.fa-save")
    end

    it "renders cancel link when cancel_path provided" do
      component = described_class.new(cancel_path: "/admin/pages")
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_link("Cancel", href: "/admin/pages")
    end

    it "does not render cancel link when cancel_path is nil" do
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).not_to have_link("Cancel")
    end

    it "applies border and spacing classes" do
      component = described_class.new
      output = Capybara.string(render_inline(component).to_html)

      expect(output).to have_css("div.border-t")
      expect(output).to have_css("div.mt-6")
      expect(output).to have_css("div.pt-4")
    end
  end

  describe "#computed_icon" do
    it "returns fa-plus for create actions" do
      component = described_class.new(submit_text: "Create Page")
      expect(component.computed_icon).to eq("fa-plus")
    end

    it "returns fa-plus for add actions" do
      component = described_class.new(submit_text: "Add Item")
      expect(component.computed_icon).to eq("fa-plus")
    end

    it "returns fa-check for update actions" do
      component = described_class.new(submit_text: "Update")
      expect(component.computed_icon).to eq("fa-check")
    end

    it "returns fa-check for save actions" do
      component = described_class.new(submit_text: "Save Changes")
      expect(component.computed_icon).to eq("fa-check")
    end

    it "returns fa-trash for delete actions" do
      component = described_class.new(submit_text: "Delete")
      expect(component.computed_icon).to eq("fa-trash")
    end

    it "returns explicit icon when provided" do
      component = described_class.new(submit_text: "Create", icon: "fa-custom")
      expect(component.computed_icon).to eq("fa-custom")
    end
  end

  describe "#submit_data_attrs" do
    it "includes disable_with attribute" do
      component = described_class.new
      expect(component.submit_data_attrs[:disable_with]).to eq("Saving...")
    end

    it "includes action when submit_action provided" do
      component = described_class.new(submit_action: "editor#save")
      expect(component.submit_data_attrs[:action]).to eq("editor#save")
    end

    it "does not include action when submit_action is nil" do
      component = described_class.new
      expect(component.submit_data_attrs).not_to have_key(:action)
    end
  end
end
