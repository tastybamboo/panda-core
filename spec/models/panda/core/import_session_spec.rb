# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::ImportSession, type: :model do
  let(:user) { Panda::Core::User.create!(name: "Import User", email: "import@example.com") }

  # Create a test class that includes Importable for testing
  let(:importable_class_name) { "Panda::Core::User" }

  before do
    # Ensure User includes Importable for testing purposes
    unless Panda::Core::User.include?(Panda::Core::Importable)
      Panda::Core::User.include(Panda::Core::Importable)
    end
  end

  def build_session(attrs = {})
    described_class.new({
      user: user,
      importable_type: importable_class_name,
      status: "pending"
    }.merge(attrs))
  end

  describe "associations" do
    it { should belong_to(:user).class_name("Panda::Core::User") }
    it { should belong_to(:tenant).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:importable_type) }

    it "validates status inclusion" do
      session = build_session(status: "pending")
      expect(session).to be_valid

      session.status = "invalid_status"
      expect(session).not_to be_valid
    end

    it "accepts all valid statuses" do
      %w[pending mapping previewing importing complete failed].each do |status|
        session = build_session(status: status)
        expect(session).to be_valid, "Expected status '#{status}' to be valid"
      end
    end

    it "validates importable_type must be importable" do
      session = build_session(importable_type: "String")
      expect(session).not_to be_valid
      expect(session.errors[:importable_type]).to include("is not importable")
    end

    it "validates importable_type must be a valid class" do
      session = build_session(importable_type: "NonexistentClass")
      expect(session).not_to be_valid
      expect(session.errors[:importable_type]).to include("is not a valid class")
    end
  end

  describe "#importable_class" do
    it "returns the importable class" do
      session = build_session
      expect(session.importable_class).to eq(Panda::Core::User)
    end

    it "raises for unknown importable types" do
      session = build_session(importable_type: "NonexistentClass")
      expect { session.importable_class }.to raise_error(ArgumentError, /Unknown importable type/)
    end

    it "raises for non-importable types" do
      session = build_session(importable_type: "String")
      expect { session.importable_class }.to raise_error(ArgumentError, /is not importable/)
    end
  end

  describe "#file_parser" do
    it "returns nil when no file is attached" do
      session = build_session
      expect(session.file_parser).to be_nil
    end
  end

  describe "#file_headers" do
    it "returns empty array when no file is attached" do
      session = build_session
      expect(session.file_headers).to eq([])
    end
  end

  describe "#file_rows" do
    it "returns empty array when no file is attached" do
      session = build_session
      expect(session.file_rows).to eq([])
    end
  end

  describe "#preview_rows" do
    it "returns empty array when no file is attached" do
      session = build_session
      expect(session.preview_rows).to eq([])
    end

    it "limits to the specified number of rows" do
      session = build_session
      allow(session).to receive(:file_rows).and_return(
        (1..10).map { |i| {"name" => "Row #{i}"} }
      )
      expect(session.preview_rows(limit: 3).size).to eq(3)
    end

    it "defaults to 5 rows" do
      session = build_session
      allow(session).to receive(:file_rows).and_return(
        (1..10).map { |i| {"name" => "Row #{i}"} }
      )
      expect(session.preview_rows.size).to eq(5)
    end
  end

  describe "#progress_percentage" do
    it "returns 0 when total_rows is zero" do
      session = build_session
      session.total_rows = 0
      session.processed_rows = 0
      expect(session.progress_percentage).to eq(0)
    end

    it "calculates the correct percentage" do
      session = build_session
      session.total_rows = 100
      session.processed_rows = 50
      expect(session.progress_percentage).to eq(50)
    end

    it "rounds to the nearest integer" do
      session = build_session
      session.total_rows = 3
      session.processed_rows = 1
      expect(session.progress_percentage).to eq(33)
    end

    it "returns 100 when all rows are processed" do
      session = build_session
      session.total_rows = 10
      session.processed_rows = 10
      expect(session.progress_percentage).to eq(100)
    end
  end

  describe "status query methods" do
    describe "#complete?" do
      it "returns true when status is complete" do
        session = build_session(status: "complete")
        expect(session).to be_complete
      end

      it "returns false when status is not complete" do
        session = build_session(status: "pending")
        expect(session).not_to be_complete
      end
    end

    describe "#importing?" do
      it "returns true when status is importing" do
        session = build_session(status: "importing")
        expect(session).to be_importing
      end

      it "returns false when status is not importing" do
        session = build_session(status: "pending")
        expect(session).not_to be_importing
      end
    end

    describe "#failed?" do
      it "returns true when status is failed" do
        session = build_session(status: "failed")
        expect(session).to be_failed
      end

      it "returns false when status is not failed" do
        session = build_session(status: "pending")
        expect(session).not_to be_failed
      end
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by created_at desc" do
        old = described_class.create!(user: user, importable_type: importable_class_name, status: "pending", created_at: 2.days.ago)
        new = described_class.create!(user: user, importable_type: importable_class_name, status: "pending", created_at: 1.day.ago)

        expect(described_class.recent.first).to eq(new)
        expect(described_class.recent.last).to eq(old)
      end
    end
  end

  describe "STATUSES" do
    it "includes the expected statuses" do
      expect(described_class::STATUSES).to eq(%w[pending mapping previewing importing complete failed])
    end
  end
end
