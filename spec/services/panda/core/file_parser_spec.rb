# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::FileParser do
  describe ".supported?" do
    it "returns true for CSV files" do
      expect(described_class.supported?("data.csv")).to be true
    end

    it "returns true for TSV files" do
      expect(described_class.supported?("data.tsv")).to be true
    end

    it "returns true for XLSX files" do
      expect(described_class.supported?("data.xlsx")).to be true
    end

    it "returns false for unsupported formats" do
      expect(described_class.supported?("data.txt")).to be false
      expect(described_class.supported?("data.pdf")).to be false
    end
  end

  describe ".xls?" do
    it "returns true for XLS files" do
      expect(described_class.xls?("data.xls")).to be true
    end

    it "returns false for non-XLS files" do
      expect(described_class.xls?("data.csv")).to be false
    end
  end

  describe "CSV parsing" do
    let(:csv_content) { "name,email\nAlice,alice@example.com\nBob,bob@example.com\n" }
    let(:parser) { described_class.new("test.csv", csv_content) }

    it "parses headers" do
      expect(parser.headers).to eq(["name", "email"])
    end

    it "parses rows as hashes" do
      expect(parser.rows).to eq([
        {"name" => "Alice", "email" => "alice@example.com"},
        {"name" => "Bob", "email" => "bob@example.com"}
      ])
    end
  end

  describe "TSV parsing" do
    let(:tsv_content) { "name\temail\nAlice\talice@example.com\n" }
    let(:parser) { described_class.new("test.tsv", tsv_content) }

    it "parses tab-separated headers" do
      expect(parser.headers).to eq(["name", "email"])
    end

    it "parses tab-separated rows" do
      expect(parser.rows.first).to eq({"name" => "Alice", "email" => "alice@example.com"})
    end
  end

  describe "unsupported format" do
    it "raises UnsupportedFormatError" do
      parser = described_class.new("test.txt", "content")
      expect { parser.headers }.to raise_error(described_class::UnsupportedFormatError)
    end
  end
end
