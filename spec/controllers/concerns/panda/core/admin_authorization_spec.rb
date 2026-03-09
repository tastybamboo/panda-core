# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::AdminAuthorization do
  before { Panda::Core::PermissionRegistry.reset! }
  after { Panda::Core::PermissionRegistry.reset! }

  # Build a minimal test controller that includes the concern
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include Panda::Core::Authorizable
      include Panda::Core::AdminAuthorization

      attr_accessor :_current_user, :_action_name

      def current_user
        _current_user
      end

      def action_name
        _action_name || "index"
      end

      def self.name
        "Admin::TestController"
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:admin_user) { instance_double("User", admin?: true) }
  let(:regular_user) { instance_double("User", admin?: false) }

  describe "#enforce_registry_permissions!" do
    context "when user is admin" do
      it "allows access without checking registry" do
        Panda::Core::PermissionRegistry.register("Admin::TestController", index: :manage_settings)
        controller._current_user = admin_user
        controller._action_name = "index"

        expect(controller.send(:enforce_registry_permissions!)).to be_nil
      end
    end

    context "when controller is not in registry" do
      it "allows access for any authenticated user" do
        controller._current_user = regular_user
        controller._action_name = "index"

        expect(controller.send(:enforce_registry_permissions!)).to be_nil
      end
    end

    context "when action is not in registry for the controller" do
      it "allows access" do
        Panda::Core::PermissionRegistry.register("Admin::TestController", create: :manage_settings)
        controller._current_user = regular_user
        controller._action_name = "index"

        expect(controller.send(:enforce_registry_permissions!)).to be_nil
      end
    end

    context "when action is registered and user has permission" do
      it "allows access" do
        Panda::Core::PermissionRegistry.register("Admin::TestController", index: :edit_content)

        # Set up authorization policy to allow edit_content
        original_policy = Panda::Core.config.authorization_policy
        Panda::Core.config.authorization_policy = ->(user, action, _resource) {
          action == :edit_content
        }

        controller._current_user = regular_user
        controller._action_name = "index"

        expect(controller.send(:enforce_registry_permissions!)).to be_nil
      ensure
        Panda::Core.config.authorization_policy = original_policy
      end
    end

    context "when action is registered and user lacks permission" do
      it "calls authorize! which would render 403" do
        Panda::Core::PermissionRegistry.register("Admin::TestController", index: :manage_settings)

        # Default policy only allows admins
        controller._current_user = regular_user
        controller._action_name = "index"

        # authorize! would redirect/render, so we test it calls authorize!
        expect(controller).to receive(:authorize!).with(:manage_settings)
        controller.send(:enforce_registry_permissions!)
      end
    end
  end
end
