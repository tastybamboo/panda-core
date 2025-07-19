require "rails_helper"
require_relative "../../../../lib/generators/panda/core/install_generator"
require "support/generator_spec_helper"

RSpec.describe Panda::Core::InstallGenerator, type: :generator do
  describe "installation" do
    it "copies migrations" do
      run_generator(["--orm=active_record"])
      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "20250121012333_logidze_install"
            migration "20250121012334_enable_hstore"
          end
        end
      }
    end

    it "copies initializer" do
      run_generator(["--orm=active_record"])
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
