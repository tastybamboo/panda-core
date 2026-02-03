# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Authorizable do
  # Create a test controller class that includes the concern
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include Panda::Core::Authorizable

      # Stub current_user method
      attr_accessor :_current_user

      def current_user
        _current_user
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:admin_user) { create_admin_user }
  let(:regular_user) { create_regular_user }

  before do
    # Reset to default policy before each test
    Panda::Core.config.authorization_policy = ->(user, action, resource) { user.admin? }
  end

  after do
    Panda::Core.reset_config!
  end

  describe "#authorized_for?" do
    context "with no current user" do
      it "returns false" do
        controller._current_user = nil
        expect(controller.authorized_for?(:edit_content)).to be false
      end
    end

    context "with an admin user" do
      it "returns true for any action" do
        controller._current_user = admin_user
        expect(controller.authorized_for?(:edit_content)).to be true
        expect(controller.authorized_for?(:manage_roles)).to be true
        expect(controller.authorized_for?(:nonexistent_permission)).to be true
      end
    end

    context "with a non-admin user and default policy" do
      it "returns false" do
        controller._current_user = regular_user
        expect(controller.authorized_for?(:edit_content)).to be false
      end
    end

    context "with a non-admin user and custom policy" do
      before do
        Panda::Core.config.authorization_policy = ->(user, action, _resource) {
          action == :edit_content
        }
      end

      it "delegates to the custom policy" do
        controller._current_user = regular_user
        expect(controller.authorized_for?(:edit_content)).to be true
        expect(controller.authorized_for?(:manage_roles)).to be false
      end
    end

    context "with a resource parameter" do
      it "passes the resource to the policy" do
        resource = double("Page")
        received_resource = nil
        Panda::Core.config.authorization_policy = ->(user, action, res) {
          received_resource = res
          true
        }

        controller._current_user = regular_user
        controller.authorized_for?(:edit_content, resource)
        expect(received_resource).to eq(resource)
      end
    end
  end

  describe "#can?" do
    it "is an alias for authorized_for?" do
      controller._current_user = admin_user
      expect(controller.can?(:anything)).to be true

      controller._current_user = regular_user
      expect(controller.can?(:anything)).to be false
    end
  end

  describe "#authorized_for_admin_access?" do
    context "with no current user" do
      it "returns false" do
        controller._current_user = nil
        expect(controller.authorized_for_admin_access?).to be false
      end
    end

    context "with an admin user" do
      it "returns true" do
        controller._current_user = admin_user
        expect(controller.authorized_for_admin_access?).to be true
      end
    end

    context "with a non-admin user and default policy" do
      it "returns false" do
        controller._current_user = regular_user
        expect(controller.authorized_for_admin_access?).to be false
      end
    end

    context "with a custom policy that grants access_admin" do
      before do
        Panda::Core.config.authorization_policy = ->(user, action, _resource) {
          action == :access_admin
        }
      end

      it "returns true for non-admin users" do
        controller._current_user = regular_user
        expect(controller.authorized_for_admin_access?).to be true
      end
    end
  end

  describe ".require_permission" do
    it "registers a before_action that calls authorize!" do
      test_class = Class.new(ActionController::Base) do
        include Panda::Core::Authorizable
        require_permission :edit_content, only: [:edit, :update]
      end

      # Check that the before_action was registered
      callbacks = test_class._process_action_callbacks.select { |c| c.kind == :before }
      expect(callbacks).not_to be_empty
    end
  end
end
