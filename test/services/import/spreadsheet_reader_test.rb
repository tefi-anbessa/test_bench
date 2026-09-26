require "test_helper"

module Import
  class SpreadsheetReaderTest < ActiveSupport::TestCase
    # file_fixture only looks in test/fixtures/files/ itself (no recursion into
    # subdirectories), so fixtures namespaced under files/import/ are found here
    # directly rather than via file_fixture.
    def import_fixture(filename)
      Rails.root.join("test/fixtures/files/import", filename)
    end

    EXPECTED_ROWS = [
      { "Tag Number" => "PT0001A", "Discipline" => "E", "Service" => "Pressure Transmitter", "Notes" => "First row" },
      { "Tag Number" => "FT0002", "Discipline" => "M", "Service" => "Flow Transmitter", "Notes" => "Second row" }
    ].freeze

    test "csv, xlsx and ods fixtures converted from the same source all read identically" do
      %w[tags.csv tags.xlsx tags.ods].each do |filename|
        path = import_fixture(filename)
        reader = SpreadsheetReader.new(path, original_filename: filename)

        assert_equal ["Tag Number", "Discipline", "Service", "Notes"], reader.headers, "headers for #{filename}"
        assert_equal EXPECTED_ROWS, reader.rows, "rows for #{filename}"
      end
    end

    test "reads correctly from a tempfile path with no real extension, given the original filename" do
      Tempfile.create(["upload", ""]) do |tempfile|
        tempfile.write(File.read(import_fixture("tags.csv")))
        tempfile.flush

        reader = SpreadsheetReader.new(tempfile.path, original_filename: "tags.csv")
        assert_equal EXPECTED_ROWS, reader.rows
      end
    end

    test "strips a UTF-8 byte-order mark from a CSV without corrupting the first header" do
      Tempfile.create(["upload", ".csv"]) do |tempfile|
        tempfile.binmode
        tempfile.write("\xEF\xBB\xBFTag Number,Discipline\nPT0001A,E\n")
        tempfile.flush

        reader = SpreadsheetReader.new(tempfile.path, original_filename: "tags.csv")
        assert_equal ["Tag Number", "Discipline"], reader.headers
        assert_equal [{ "Tag Number" => "PT0001A", "Discipline" => "E" }], reader.rows
      end
    end

    test "raises a clear error for an unsupported file type" do
      error = assert_raises(SpreadsheetReader::UnsupportedFormatError) do
        SpreadsheetReader.new(import_fixture("tags.csv"), original_filename: "tags.pdf").rows
      end
      assert_match "tags.pdf", error.message
    end

    test "raises a clear error for a file that isn't really a spreadsheet" do
      Tempfile.create(["not_a_spreadsheet", ".xlsx"]) do |tempfile|
        tempfile.write("this is not a real xlsx file")
        tempfile.flush

        error = assert_raises(SpreadsheetReader::UnsupportedFormatError) do
          SpreadsheetReader.new(tempfile.path, original_filename: "tags.xlsx").rows
        end
        assert_match "tags.xlsx", error.message
      end
    end
  end
end
