# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::TagsPanelComponent, type: :component do
  let(:tag) { Panda::Core::Tag.new(name: "Important", colour: "#ff0000") }

  it "renders a panel with Tags heading" do
    render_inline(described_class.new(tags: [tag]))
    output = Capybara.string(rendered_content)

    expect(output).to have_text("Tags")
    expect(output).to have_text("Important")
  end

  it "renders a TagBadgeComponent for each tag" do
    tag2 = Panda::Core::Tag.new(name: "Urgent", colour: "#00ff00")
    render_inline(described_class.new(tags: [tag, tag2]))
    output = Capybara.string(rendered_content)

    expect(output).to have_text("Important")
    expect(output).to have_text("Urgent")
  end

  it "does not render when tags are empty" do
    component = described_class.new(tags: [])
    expect(component.render?).to be false
  end

  it "supports custom heading text" do
    render_inline(described_class.new(tags: [tag], heading: "Categories"))
    output = Capybara.string(rendered_content)

    expect(output).to have_text("Categories")
  end
end
