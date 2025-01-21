require "rails_helper"
require_relative "../../../../lib/generators/panda/core/install_generator"
require "support/generator_spec_helper"

RSpec.describe Panda::Core::InstallGenerator, type: :generator do
  describe "installation" do
    it "copies migrations" do
      run_generator
      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_panda_core_users"
            migration "create_panda_core_user_identities"
          end
        end
      }
    end

    it "copies initializer" do
      run_generator
      expect(destination_root).to have_structure {
        directory "config" do
          directory "initializers" do
            file "panda_core.rb" do
              contains "Panda::Core.configure do |config|"
              contains "config.session_token_cookie = :panda_session"
              contains "config.user_class = \"Panda::Core::User\""
              contains "config.user_identity_class = \"Panda::Core::UserIdentity\""
            end
          end
        end
      }
    end
  end
end
