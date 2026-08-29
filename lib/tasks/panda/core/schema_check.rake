# frozen_string_literal: true

require "fileutils"
require "stringio"

# CI builds its database with db:schema:load, which never enumerates db/migrate.
# A migration edited without regenerating schema.rb therefore drifts silently:
# every spec keeps running against the committed schema while host applications,
# which do run the migrations, get something else.
#
# This task closes that gap. It replays every migration in order against an
# empty database and diffs the resulting dump against the committed schema.rb.
#
# Engine migrations are copied with their original timestamps rather than
# through panda_core:install:migrations, which re-stamps them at copy time. The
# original stamps are what the committed schema.rb records as its version.

namespace :panda do
  namespace :core do
    namespace :schema do
      desc "Check that db/migrate applied from empty reproduces the committed schema.rb"
      task check: :environment do
        connection = ActiveRecord::Base.connection
        existing = connection.tables - %w[schema_migrations ar_internal_metadata]

        if existing.any?
          abort <<~MESSAGE
            panda:core:schema:check needs an empty database, but found #{existing.size} table(s).

            Point DATABASE_URL at a scratch database first, for example:

              DATABASE_URL=postgres://localhost/panda_core_schema_check \\
                bundle exec rails db:drop db:create panda:core:schema:check
          MESSAGE
        end

        work_dir = Rails.root.join("tmp/panda_core_schema_check")
        migrate_dir = work_dir.join("migrate")
        FileUtils.rm_rf(work_dir)
        FileUtils.mkdir_p(migrate_dir)

        sources = Rails.application.config.paths["db/migrate"].expanded +
          Panda::Core::Engine.config.paths["db/migrate"].expanded

        collected = {}
        sources.each do |source|
          Dir[File.join(source, "*.rb")].sort.each do |path|
            version = File.basename(path)[/\A\d+/]
            if collected.key?(version)
              abort "Duplicate migration version #{version}:\n  #{collected[version]}\n  #{path}"
            end
            collected[version] = path
            FileUtils.cp(path, migrate_dir.join(File.basename(path)))
          end
        end

        puts "Applying #{collected.size} migrations from empty..."
        ActiveRecord::MigrationContext.new(migrate_dir.to_s).migrate

        dump = StringIO.new
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, dump)

        committed_path = Rails.root.join("db/schema.rb")
        committed = committed_path.read

        if dump.string == committed
          puts "Schema check passed: db/migrate reproduces #{committed_path}"
          next
        end

        actual_path = work_dir.join("schema.from_migrate.rb")
        actual_path.write(dump.string)

        puts
        puts "Schema drift detected between the migrations and the committed schema."
        puts "  committed:       #{committed_path}"
        puts "  from migrations: #{actual_path}"
        puts
        system("diff", "-u", committed_path.to_s, actual_path.to_s)

        abort <<~MESSAGE

          db/migrate does not reproduce the committed schema.rb.

          Either the migration is wrong, or schema.rb was never regenerated after
          it changed.

          Note that `rails db:migrate` will not regenerate it: the engine's
          db/migrate is not on the application's migration path, so only
          spec/dummy's own migrations would run. If the migrations are correct,
          copy the dump this task just produced over the committed schema:

            cp #{actual_path} #{committed_path}
        MESSAGE
      end
    end
  end
end
