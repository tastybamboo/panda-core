# frozen_string_literal: true

require "csv"

module Panda
  module Core
    class FileParser
      class UnsupportedFormatError < StandardError; end

      SUPPORTED_EXTENSIONS = %w[.csv .tsv .xlsx].freeze

      def initialize(filename, content)
        @filename = filename
        @content = content
        @extension = File.extname(filename).downcase
      end

      def headers
        @headers ||= parse.first
      end

      def rows
        @rows ||= parse.last
      end

      def self.supported?(filename)
        ext = File.extname(filename).downcase
        SUPPORTED_EXTENSIONS.include?(ext)
      end

      def self.xls?(filename)
        File.extname(filename).downcase == ".xls"
      end

      private

      def parse
        @parsed ||= case @extension
        when ".csv"
          parse_csv
        when ".tsv"
          parse_tsv
        when ".xlsx"
          parse_xlsx
        else
          raise UnsupportedFormatError, "Unsupported file format: #{@extension}"
        end
      end

      def parse_csv
        parsed = CSV.parse(@content, headers: true)
        headers = parsed.headers
        rows = parsed.map(&:to_h)
        [headers, rows]
      end

      def parse_tsv
        parsed = CSV.parse(@content, headers: true, col_sep: "\t")
        headers = parsed.headers
        rows = parsed.map(&:to_h)
        [headers, rows]
      end

      def parse_xlsx
        require "xsv"

        workbook = Xsv.open(StringIO.new(@content))
        sheet = workbook.sheets.first
        sheet.parse_headers!

        [sheet.headers, sheet.to_a]
      end
    end
  end
end
