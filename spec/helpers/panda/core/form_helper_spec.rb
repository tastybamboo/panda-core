# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::FormHelper, type: :helper do
  describe "#panda_form_with" do
    let(:user) { Panda::Core::User.new(name: "Test", email: "test@example.com") }

    it "sets the form builder to Panda::Core::FormBuilder" do
      form_html = helper.panda_form_with(model: user, url: "/test") { |f| f.text_field(:name) }
      expect(form_html).to include('name="user[name]"')
      # FormBuilder wraps in container div
      expect(form_html).to include("panda-core-field-container")
    end

    it "applies default CSS classes" do
      form_html = helper.panda_form_with(model: user, url: "/test") { "" }
      expect(form_html).to include("block visible")
    end

    it "merges custom CSS classes" do
      form_html = helper.panda_form_with(model: user, url: "/test", class: "my-form") { "" }
      expect(form_html).to include("block visible")
      expect(form_html).to include("my-form")
    end
  end
end
