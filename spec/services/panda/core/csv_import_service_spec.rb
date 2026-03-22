# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::CSVImportService do
  let(:admin_user) { create_admin_user }

  before do
    unless Panda::Core::User.include?(Panda::Core::Importable)
      Panda::Core::User.include(Panda::Core::Importable)
    end
  end

  def create_import_session(attrs = {})
    session = Panda::Core::ImportSession.create!({
      importable_type: "Panda::Core::User",
      user: admin_user,
      status: "previewing",
      column_mapping: {"name" => "name", "email" => "email"}
    }.merge(attrs))

    csv_content = "name,email\nAlice,alice-import@example.com\nBob,bob-import@example.com\n"
    session.import_file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
    session
  end

  describe "#call" do
    it "updates status to importing then complete" do
      import_session = create_import_session

      # Skip actual row processing by stubbing the importable class
      allow(import_session).to receive(:importable_class).and_return(nil)
      allow(import_session).to receive(:file_rows).and_return([])

      described_class.new(import_session).call
      import_session.reload

      expect(import_session.status).to eq("complete")
      expect(import_session.started_at).to be_present
      expect(import_session.completed_at).to be_present
    end

    it "sets total_rows from the file" do
      import_session = create_import_session
      allow(import_session).to receive(:file_rows).and_return([])

      described_class.new(import_session).call
      import_session.reload

      expect(import_session.total_rows).to eq(0)
    end

    it "sets status to failed on exception" do
      import_session = create_import_session
      allow(import_session).to receive(:file_rows).and_raise(StandardError, "Parse error")

      expect {
        described_class.new(import_session).call
      }.to raise_error(StandardError, "Parse error")

      import_session.reload
      expect(import_session.status).to eq("failed")
      expect(import_session.completed_at).to be_present
    end
  end
end
