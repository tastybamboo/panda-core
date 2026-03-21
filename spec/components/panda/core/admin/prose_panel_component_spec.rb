# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::ProsePanelComponent, type: :component do
  it "renders text in a prose-styled panel" do
    render_inline(described_class.new(heading: "Notes", text: "Some notes here"))
    output = Capybara.string(rendered_content)

    expect(output).to have_text("Notes")
    expect(output).to have_text("Some notes here")
    expect(output).to have_css("div.prose.prose-sm")
  end

  it "does not render when text is blank" do
    component = described_class.new(heading: "Notes", text: "")
    expect(component.render?).to be false
  end

  it "does not render when text is nil" do
    component = described_class.new(heading: "Notes", text: nil)
    expect(component.render?).to be false
  end

  it "supports custom heading" do
    render_inline(described_class.new(heading: "Description", text: "A description"))
    output = Capybara.string(rendered_content)

    expect(output).to have_text("Description")
  end

  it "supports additional prose classes" do
    render_inline(described_class.new(heading: "Notes", text: "Content", prose_class: "text-gray-600"))
    output = Capybara.string(rendered_content)

    expect(output).to have_css("div.prose.text-gray-600")
  end
end
