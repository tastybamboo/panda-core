# frozen_string_literal: true

# panda_core_tags.tenant_id and panda_core_import_sessions.tenant_id back
# `belongs_to :tenant, polymorphic: true`. A polymorphic id has to be able to hold
# whatever primary key the host app's tenant model uses, which for every current
# panda host is a uuid — so the column has to be a string.
#
# #150 established that for panda_core_tags and #151 fixed it by editing the
# already-released CreatePandaCoreTags migration in place. That fixed what a fresh
# `db:migrate` builds and nothing else: every database that had already run the
# migration kept its bigint column, and `db:schema:load` kept building bigint too,
# because spec/dummy/db/schema.rb was never regenerated. panda_core_import_sessions
# was never fixed at all.
#
# This converts the columns wherever they are still integers, and leaves string and
# uuid columns (a host app that typed them itself) alone.
class NormalisePolymorphicTenantIdColumns < ActiveRecord::Migration[8.1]
  TABLES = %i[panda_core_tags panda_core_import_sessions].freeze

  def up
    TABLES.each do |table|
      next unless integer_tenant_id?(table)

      change_column table, :tenant_id, :string
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "tenant_id holds host tenant primary keys, which are not necessarily integers"
  end

  private

  def integer_tenant_id?(table)
    return false unless table_exists?(table)

    column = columns(table).find { |c| c.name == "tenant_id" }
    column&.type == :integer
  end
end
