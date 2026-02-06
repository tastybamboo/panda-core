# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::ContributorsSummaryComponent, type: :component do
  let(:user1) do
    double("User",
      id: "user-1",
      firstname: "Alice",
      lastname: "Smith",
      name: "Alice Smith",
      email: "alice@example.com",
      respond_to?: true,
      avatar_url: nil)
  end

  let(:user2) do
    double("User",
      id: "user-2",
      firstname: "Bob",
      lastname: "Jones",
      name: "Bob Jones",
      email: "bob@example.com",
      respond_to?: true,
      avatar_url: nil)
  end

  before do
    allow(user1).to receive(:respond_to?).with(:avatar_url).and_return(false)
    allow(user1).to receive(:respond_to?).with(:name).and_return(true)
    allow(user2).to receive(:respond_to?).with(:avatar_url).and_return(false)
    allow(user2).to receive(:respond_to?).with(:name).and_return(true)
  end

  describe "rendering" do
    it "renders contributor names" do
      render_inline(described_class.new(
        contributors: [user1, user2],
        total_count: 5,
        last_updated_at: 2.hours.ago
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("Alice Smith")
      expect(output).to have_text("Bob Jones")
    end

    it "renders count and contributor totals" do
      render_inline(described_class.new(
        contributors: [user1],
        total_count: 3,
        last_updated_at: 1.day.ago
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("1 contributor")
      expect(output).to have_text("3 versions")
    end

    it "uses custom count label" do
      render_inline(described_class.new(
        contributors: [user1],
        total_count: 7,
        count_label: "edit",
        last_updated_at: 1.day.ago
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("7 edits")
    end

    it "uses custom heading" do
      render_inline(described_class.new(
        contributors: [user1],
        total_count: 1,
        heading: "Authors",
        last_updated_at: 1.hour.ago
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("Authors")
    end

    it "pluralizes contributor count correctly" do
      render_inline(described_class.new(
        contributors: [user1, user2],
        total_count: 1,
        last_updated_at: 1.hour.ago
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("2 contributors")
      expect(output).to have_text("1 version")
    end

    it "renders with empty contributors" do
      render_inline(described_class.new(
        contributors: [],
        total_count: 0,
        last_updated_at: Time.current
      ))
      output = Capybara.string(rendered_content)

      expect(output).to have_text("0 contributors")
      expect(output).to have_text("0 versions")
    end
  end
end
