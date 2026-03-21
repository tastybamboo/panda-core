# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::DeleteButtonComponent, type: :component do
  let(:component) do
    described_class.new(
      text: "Delete Person",
      path: "/admin/people/1",
      confirm: "Are you sure?"
    )
  end

  it "renders a button_to form with DELETE method" do
    render_inline(component)
    output = Capybara.string(rendered_content)

    expect(output).to have_css("form[method='post']")
    expect(output).to have_css("input[name='_method'][value='delete']", visible: :hidden)
    expect(output).to have_button("Delete Person")
  end

  it "includes turbo confirmation data attribute" do
    render_inline(component)
    output = Capybara.string(rendered_content)

    expect(output).to have_css("button[data-turbo-confirm='Are you sure?']")
  end

  it "uses error styling by default" do
    render_inline(component)
    output = Capybara.string(rendered_content)

    expect(output).to have_css("button.text-error-600")
  end

  it "wraps in a right-aligned container" do
    render_inline(component)
    output = Capybara.string(rendered_content)

    expect(output).to have_css("div.justify-end")
  end

  it "points to the correct path" do
    render_inline(component)
    output = Capybara.string(rendered_content)

    expect(output).to have_css("form[action='/admin/people/1']")
  end
end
