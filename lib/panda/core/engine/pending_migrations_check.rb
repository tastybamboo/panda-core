# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      module PendingMigrationsCheck
        extend ActiveSupport::Concern

        included do
          initializer "panda_core.pending_migrations_check", after: :load_config_initializers do
            config.after_initialize do
              next unless Rails.env.local?

              check_for_pending_panda_migrations
            rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
              # Skip when DB isn't available (asset precompilation, etc.)
            end
          end
        end

        private

        def check_for_pending_panda_migrations
          context = ActiveRecord::MigrationContext.new(Rails.application.paths["db/migrate"].to_a)
          return unless context.needs_migration?

          pending = context.open.pending_migrations
          panda_pending = pending.select { |m| m.filename.match?(/panda/i) }
          return if panda_pending.empty?

          Rails.logger.warn(
            "\n⚠️  #{panda_pending.size} pending Panda migration(s) detected.\n" \
            "   Run: bundle exec rake panda:install_migrations\n" \
            "   (or: bin/rails panda_core:install:migrations panda_cms:install:migrations " \
            "panda_helpdesk:install:migrations db:migrate)\n"
          )
        end
      end
    end
  end
end
