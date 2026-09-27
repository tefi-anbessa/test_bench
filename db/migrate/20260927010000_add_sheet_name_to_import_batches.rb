class AddSheetNameToImportBatches < ActiveRecord::Migration[8.0]
  def change
    # Which worksheet within the uploaded workbook this batch reads from -
    # set once the user picks one, for a file with more than one sheet (see
    # Import::BatchesController#show). Null for a single-sheet file/CSV,
    # where there's nothing to choose.
    add_column :import_batches, :sheet_name, :string
  end
end
