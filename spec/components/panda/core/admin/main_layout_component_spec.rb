# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Admin::MainLayoutComponent do
  describe "initialization" do
    it "accepts user property" do
      user = instance_double("User")
      component = described_class.new(user: user)
      expect(component).to be_a(described_class)
    end

    it "accepts breadcrumbs property" do
      user = instance_double("User")
      breadcrumbs = []
      component = described_class.new(user: user, breadcrumbs: breadcrumbs)
      expect(component).to be_a(described_class)
    end

    it "has defaults for optional properties" do
      user = instance_double("User")
      component = described_class.new(user: user)
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders container structure" do
      user = instance_double("User")
      component = described_class.new(user: user)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("panda-container")
      expect(html).to include("panda-inner-container")
      expect(html).to include("panda-main")
      expect(html).to include("panda-primary-content")
    end

    it "includes sidebar controller" do
      user = instance_double("User")
      component = described_class.new(user: user)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("bg-gradient-admin")
    end

    it "includes slideover panel structure" do
      user = instance_double("User")
      component = described_class.new(user: user)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("slideover")
      expect(html).to include("data-toggle-target")
    end

    it "includes escape key handler" do
      user = instance_double("User")
      component = described_class.new(user: user)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("e.key === 'Escape'")
    end
  end
end
