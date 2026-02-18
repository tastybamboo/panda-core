# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::WidgetRegistry do
  before do
    described_class.reset!
    Panda::Core.reset_config!
  end

  after do
    described_class.reset!
    Panda::Core.reset_config!
  end

  let(:user) { double("User", admin?: true) }

  describe ".register" do
    it "stores a widget definition" do
      described_class.register("Test Widget", component: ->(user) { "widget" })
      expect(described_class.widgets.length).to eq(1)
      expect(described_class.widgets.first[:label]).to eq("Test Widget")
    end
  end

  describe ".build" do
    it "returns legacy widgets from admin_dashboard_widgets lambda" do
      widget = double("Widget")
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [widget] }

      result = described_class.build(user)
      expect(result).to eq([widget])
    end

    it "returns registered widgets instantiated via component lambda" do
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [] }
      described_class.register("Activity", component: ->(user) { "activity_widget" })

      result = described_class.build(user)
      expect(result).to eq(["activity_widget"])
    end

    it "combines legacy and registered widgets" do
      legacy = double("Legacy")
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [legacy] }
      described_class.register("New", component: ->(user) { "new_widget" })

      result = described_class.build(user)
      expect(result).to eq([legacy, "new_widget"])
    end

    it "filters out widgets where visible: returns false" do
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [] }
      described_class.register("Admin Only",
        component: ->(user) { "admin_widget" },
        visible: ->(user) { user.admin? })
      described_class.register("Hidden",
        component: ->(user) { "hidden_widget" },
        visible: ->(user) { false })

      result = described_class.build(user)
      expect(result).to eq(["admin_widget"])
    end

    it "sorts widgets by position" do
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [] }
      described_class.register("Third", component: ->(user) { "c" }, position: 3)
      described_class.register("First", component: ->(user) { "a" }, position: 1)
      described_class.register("Second", component: ->(user) { "b" }, position: 2)

      result = described_class.build(user)
      expect(result).to eq(["a", "b", "c"])
    end

    it "returns empty array when no widgets configured" do
      Panda::Core.config.admin_dashboard_widgets = nil
      result = described_class.build(user)
      expect(result).to eq([])
    end

    it "passes user to component lambda" do
      Panda::Core.config.admin_dashboard_widgets = ->(user) { [] }
      described_class.register("User Widget",
        component: ->(user) { "widget_for_#{user.admin? ? "admin" : "user"}" })

      result = described_class.build(user)
      expect(result).to eq(["widget_for_admin"])
    end
  end

  describe ".reset!" do
    it "clears all registered widgets" do
      described_class.register("Test", component: ->(user) { "widget" })
      described_class.reset!
      expect(described_class.widgets).to be_empty
    end
  end
end
