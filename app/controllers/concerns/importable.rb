# Mixed into a model's own controller (see TagsController) to add a
# spreadsheet-import entry point as two plain actions, `import`/
# `create_import`, reusing whatever before_actions that controller already
# has for its normal CRUD actions (e.g. TagsController's set_discipline
# already sets @project/@discipline from either a discipline_id or a
# project_id param) - nothing here re-derives that context.
#
# Everything after the upload (column mapping, dry-run review, commit) is
# fully generic and lives on Import::Batch / Import::BatchesController -
# not part of this concern, since it doesn't vary by model at all.
module Importable
  extend ActiveSupport::Concern

  # GET - render app/views/<controller>/import.html.erb
  def import
    authorize_import!
  end

  # POST - validate the upload, stage it as an Import::Batch, hand off to
  # the generic wizard.
  def create_import
    authorize_import!

    uploaded_file = params.require(:file)

    # Fail fast on a file that isn't even a supported spreadsheet, before
    # persisting a batch or advancing to the mapping step.
    begin
      Import::SpreadsheetReader.new(uploaded_file.tempfile.path, original_filename: uploaded_file.original_filename).headers
    rescue Import::SpreadsheetReader::UnsupportedFormatError => e
      flash.now[:alert] = e.message
      render :import, status: :unprocessable_content
      return
    end

    batch = Import::Batch.new(
      user: current_user,
      project: @project,
      discipline: @discipline,
      importer_key: importer_key,
      original_filename: uploaded_file.original_filename,
      file_data: uploaded_file.read
    )

    if batch.save
      redirect_to import_batch_path(batch)
    else
      flash.now[:alert] = batch.errors.full_messages.to_sentence
      render :import, status: :unprocessable_content
    end
  end

  private

  # Override to name the Import::Base registry key for this model (e.g. "tags").
  def importer_key
    raise NotImplementedError, "#{self.class} must define #importer_key"
  end

  # Override for a precise upfront check where one's possible (e.g. a
  # discipline-scoped import already knows which discipline, so it can
  # authorize against it directly). Left as a no-op by default: a
  # project-wide import can span several disciplines, so real per-discipline
  # authorization happens once rows (and therefore which disciplines are
  # involved) are known - see Import::Base#dry_run_rows - not here.
  def authorize_import!
  end
end
