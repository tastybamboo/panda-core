# frozen_string_literal: true

module Panda
  module Core
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Install Panda Core: create the initializer and copy migrations"

        def copy_initializer
          template "panda.rb", "config/initializers/panda.rb"
        end

        def copy_migrations
          rake "panda_core:install:migrations"
        end

        def show_readme
          say ""
          say "Panda Core installed!", :green
          say ""
          say "Next steps:"
          say "  1. Edit config/initializers/panda.rb to configure authentication"
          say "  2. Run: rails db:migrate"
          say "  3. Add gem 'panda-cms' to your Gemfile for CMS functionality"
          say ""
        end
      end
    end
  end
end
