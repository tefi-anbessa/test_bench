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
    # sheet: which worksheet to read (by name) for a workbook with more than
    # one - nil reads roo's own default (the first sheet), which is also the
    # only sheet for a single-sheet file/CSV.
    def initialize(path, original_filename:, sheet: nil)
      @path = path
      @original_filename = original_filename
      @extension = File.extname(original_filename).downcase
      @sheet = sheet
    end

    # Every sheet name in the workbook, in order - a single-element array for
    # any format without real multi-sheet support (CSV) or a workbook that
    # only has one sheet.
    def sheet_names
      spreadsheet.sheets
    end

    def headers
      # A blank header cell (a spacer/unused column, common in a wider
      # real-world sheet) comes back from roo as a nil key - excluded here
      # rather than offered as a mappable column, since there's nothing
      # meaningful to match it against and no way to label it in the mapping
      # form. Left in, it would render as an empty `column_mapping[]` select
      # name alongside the other `column_mapping[Header]` ones - confirmed
      # directly to make Rack's param parser raise
      # Rack::QueryParser::ParameterTypeError on submit, since it can't
      # reconcile array syntax and hash syntax under the same param name.
      (rows.first&.keys || []).reject(&:blank?)
    end

    def rows
      @rows ||= read_rows
    end

    private

    attr_reader :path, :original_filename, :extension, :sheet

    def spreadsheet
      @spreadsheet ||= begin
        unless SUPPORTED_EXTENSIONS.include?(extension)
          raise UnsupportedFormatError,
            "Unsupported file type #{extension.presence || "(none)"} for #{original_filename} - " \
            "expected one of #{SUPPORTED_EXTENSIONS.join(", ")}."
        end

        begin
          Roo::Spreadsheet.open(path, **open_options).tap do |s|
            s.default_sheet = sheet if sheet.present?
          end
        rescue StandardError => e
          # Broad on purpose: a corrupt file can fail this in ways specific to
          # each format's underlying parser (a malformed zip container for
          # .xlsx/.ods, malformed quoting for .csv, ...) rather than a single
          # Roo-owned exception class - any of them should read as "this
          # isn't a valid file of the type it claims to be" to the caller,
          # not surface a third-party library's own exception class. e is
          # preserved as #cause.
          raise UnsupportedFormatError, "Could not read #{original_filename}: #{e.message}"
        end
      end
    end

    def read_rows
      spreadsheet.each(headers: true, clean: true).to_a.drop(1)
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
