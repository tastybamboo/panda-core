# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::FilterPillsComponent, type: :component do
  let(:url_helper) { ->(value) { value ? "/files?category=#{value}" : "/files" } }
  let(:items) do
    [
      {label: "Documents", value: "documents"},
      {label: "Images", value: "images"}
    ]
  end

  it "renders all filter pills plus the 'All' pill" do
    component = described_class.new(items: items, url_helper: url_helper)
    output = render_inline(component).to_html

    expect(output).to include("All")
    expect(output).to include("Documents")
    expect(output).to include("Images")
  end

  it "highlights the 'All' pill when no filter is active" do
    component = described_class.new(items: items, url_helper: url_helper, active_value: nil)
    output = render_inline(component).to_html

    expect(output).to include("bg-primary-100")
  end

  it "highlights the active category pill" do
    component = described_class.new(items: items, url_helper: url_helper, active_value: "documents")
    html = render_inline(component).to_html

    # The Documents pill should have active class, "All" should have inactive
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    all_link = doc.css("a").find { |a| a.text.strip == "All" }
    docs_link = doc.css("a").find { |a| a.text.strip == "Documents" }

    expect(all_link["class"]).to include("bg-gray-100")
    expect(docs_link["class"]).to include("bg-primary-100")
  end

  it "generates correct URLs for each pill" do
    component = described_class.new(items: items, url_helper: url_helper)
    html = render_inline(component).to_html

    expect(html).to include('href="/files"')
    expect(html).to include('href="/files?category=documents"')
    expect(html).to include('href="/files?category=images"')
  end

  it "supports custom all_label" do
    component = described_class.new(items: items, url_helper: url_helper, all_label: "Show All")
    output = render_inline(component).to_html

    expect(output).to include("Show All")
  end
end
