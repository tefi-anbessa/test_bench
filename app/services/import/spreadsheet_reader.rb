# app/services/import/spreadsheet_reader.rb
module Import
  # The only file in the import framework that touches `roo` directly - every
  # format (.csv/.xlsx/.xlsm/.ods) enters the pipeline from here as the same
  # plain Array of { header_string => cell_value } row hashes, so nothing
  # above this layer needs to be format-aware.
  #
  # `roo`'s own `each(headers: true)` yields the header row itself as a
  # spurious first "data" row (each header mapped to its own name) - verified
  # directly against the gem, not assumed from its docs - so that row is
  # dropped here rather than leaking upward.
  class SpreadsheetReader
    SUPPORTED_EXTENSIONS = %w[.csv .xlsx .xlsm .ods].freeze

    class UnsupportedFormatError < StandardError; end

    # path: a local file path (e.g. an uploaded file's #path). original_filename
    # is used only to determine the real extension - an uploaded file's tempfile
    # path rarely has one, so the format can't be inferred from `path` alone.
    def initialize(path, original_filename:)
      @path = path
      @original_filename = original_filename
      @extension = File.extname(original_filename).downcase
    end

    def headers
      rows.first&.keys || []
    end

    def rows
      @rows ||= read_rows
    end

    private

    attr_reader :path, :original_filename, :extension

    def read_rows
      unless SUPPORTED_EXTENSIONS.include?(extension)
        raise UnsupportedFormatError,
          "Unsupported file type #{extension.presence || "(none)"} for #{original_filename} - " \
          "expected one of #{SUPPORTED_EXTENSIONS.join(", ")}."
      end

      begin
        sheet = Roo::Spreadsheet.open(path, **open_options)
        sheet.each(headers: true, clean: true).to_a.drop(1)
      rescue StandardError => e
        # Broad on purpose: a corrupt file can fail this in ways specific to
        # each format's underlying parser (a malformed zip container for
        # .xlsx/.ods, malformed quoting for .csv, ...) rather than a single
        # Roo-owned exception class - any of them should read as "this isn't
        # a valid file of the type it claims to be" to the caller, not
        # surface a third-party library's own exception class. e is
        # preserved as #cause.
        raise UnsupportedFormatError, "Could not read #{original_filename}: #{e.message}"
      end
    end

    def open_options
      options = { extension: extension }
      # Excel commonly writes a UTF-8 CSV with a leading byte-order mark;
      # "bom|utf-8" strips it if present and is a no-op otherwise.
      options[:csv_options] = { encoding: "bom|utf-8" } if extension == ".csv"
      options
    end
  end
end
