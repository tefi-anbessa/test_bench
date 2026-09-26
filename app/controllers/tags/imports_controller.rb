module Tags
  # Upload entry point for the Tag spreadsheet import - the only part of the
  # wizard that's model/context-specific (it establishes which project and,
  # for the discipline-scoped route, which discipline the resulting
  # Import::Batch belongs to). Every step after this is generic - see
  # ImportBatchesController.
  class ImportsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!
    before_action :set_context
    before_action :set_swatch

    def new
    end

    def create
      uploaded_file = params.require(:file)

      # Fail fast on a file that isn't even a supported spreadsheet, before
      # persisting a batch or advancing to the mapping step.
      begin
        Import::SpreadsheetReader.new(uploaded_file.tempfile.path, original_filename: uploaded_file.original_filename).headers
      rescue Import::SpreadsheetReader::UnsupportedFormatError => e
        flash.now[:alert] = e.message
        render :new, status: :unprocessable_content
        return
      end

      batch = Import::Batch.new(
        user: current_user,
        project: @project,
        discipline: @discipline,
        importer_key: "tags",
        original_filename: uploaded_file.original_filename,
        file_data: uploaded_file.read
      )

      if batch.save
        redirect_to import_batch_path(batch)
      else
        flash.now[:alert] = batch.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_context
      if params[:discipline_id]
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
        authorize @discipline.tags.build, :create?
        @project = @discipline.project
      else
        @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
        @discipline = nil
        # No single discipline exists yet to authorize a probe against here -
        # a project-wide file can span several disciplines, so per-discipline
        # authorization is enforced for real once rows (and therefore which
        # disciplines are actually involved) are known - see
        # ImportBatchesController#commit -> Import::Base#dry_run_rows.
      end
    end

    def set_swatch
      @swatch = @discipline&.swatch || Swatch.find_by(name: "app_theme")
    end
  end
end
