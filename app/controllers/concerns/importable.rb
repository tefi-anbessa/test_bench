# Mixed into a model's own controller (see TagsController) to add a
# spreadsheet-import entry point as two plain actions, `import`/
# `create_import`. The host controller's own before_actions are expected to
# set @discipline and, where relevant, @project (e.g. via its existing
# set_discipline) - @project is derived from @discipline as a fallback below
# for a controller whose set_discipline doesn't already set it (not every
# one needs to, for its own non-import actions).
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
      # Not every host controller's own set_discipline sets @project too
      # when resolving from a discipline_id param (TagsController's does;
      # DocumentsController's, e.g., doesn't need to for its own actions) -
      # derived here rather than assumed, so this concern doesn't silently
      # depend on that as an undocumented precondition.
      project: @project || @discipline&.project,
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
