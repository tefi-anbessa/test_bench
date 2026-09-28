# Generic across every importer (see Import::Base's registry) - drives every
# step of the wizard after upload (see the Importable concern, mixed into
# each model's own controller, for that entry point): confirm column
# mapping, dry-run review, commit, abort.
module Import
  class BatchesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_batch
    before_action :set_swatch

    def show
      case @batch.status
      when "uploaded"
        if needs_sheet_selection?
          setup_sheet_selection_form
          render :select_sheet
        else
          setup_mapping_form
          render :mapping
        end
      when "mapped", "validated"
        run_dry_run
        render :review
      else
        redirect_to model_index_path, notice: t(".already_finished")
      end
    end

    def update
      raise ApplicationController::ConflictError, :out_of_scope unless @batch.uploaded?

      if params.key?(:sheet_name)
        @batch.update!(sheet_name: params[:sheet_name].presence)
        redirect_to import_batch_path(@batch)
        return
      end

      @batch.column_mapping = params.require(:column_mapping).to_unsafe_h
      @batch.discipline_id = params[:single_discipline_id] if params[:single_discipline_id].present?
      @batch.create_missing_tags = params[:create_missing_tags] == "1" if @batch.importer.supports_tag_creation?
      @batch.status = :mapped
      if @batch.save
        Import::MappingPreset.remember!(user: current_user, importer_key: @batch.importer_key, column_mapping: @batch.column_mapping)
        redirect_to import_batch_path(@batch)
      else
        setup_mapping_form
        flash.now[:alert] = @batch.errors.full_messages.to_sentence
        render :mapping, status: :unprocessable_content
      end
    end

    def commit
      raise ApplicationController::ConflictError, :out_of_scope unless @batch.mapped? || @batch.validated?

      importer = @batch.importer
      rows = importer.dry_run_rows(pundit_user: pundit_user)
      result = Import::Committer.new(importer: importer, rows: rows, partial: params[:partial] == "1").call

      @batch.update!(status: :imported, row_count: result.imported_count)
      flash[:success] = t(".notice", imported: result.imported_count, skipped: result.skipped_count)
      redirect_to model_index_path
    rescue Import::Committer::InvalidRowsError => e
      flash.now[:alert] = e.message
      run_dry_run
      render :review, status: :unprocessable_content
    end

    def destroy
      @batch.update!(status: :aborted)
      redirect_to model_index_path, notice: t(".notice")
    end

    # Lets a user swap in a corrected file for this batch without losing
    # their place (discipline/tagable_type/etc. stay put) - resets the batch
    # back through sheet-select/mapping. column_mapping resets to {} since
    # the new file's headers might differ, but Import::MappingPreset (keyed
    # by user+importer_key, not by batch) re-suggests the same mapping again
    # as long as the headers still match.
    def refresh_file
      raise ApplicationController::ConflictError, :out_of_scope unless @batch.mapped? || @batch.validated?

      uploaded_file = params.require(:file)

      begin
        Import::SpreadsheetReader.new(uploaded_file.tempfile.path, original_filename: uploaded_file.original_filename).headers
      rescue Import::SpreadsheetReader::UnsupportedFormatError => e
        flash.now[:alert] = e.message
        run_dry_run
        render :review, status: :unprocessable_content
        return
      end

      @batch.update!(file_data: uploaded_file.read, original_filename: uploaded_file.original_filename,
        sheet_name: nil, column_mapping: {}, status: :uploaded, expires_at: 1.day.from_now)
      redirect_to import_batch_path(@batch)
    end

    # Lets a user return to column mapping from the review screen to adjust
    # their choices - the existing file/column_mapping/sheet_name are left
    # untouched, so the mapping page shows the same selections as before
    # (also re-suggested from Import::MappingPreset regardless, since that
    # was saved from this exact mapping on the way to review).
    def back_to_mapping
      raise ApplicationController::ConflictError, :out_of_scope unless @batch.mapped? || @batch.validated?

      @batch.update!(status: :uploaded)
      redirect_to import_batch_path(@batch)
    end

    private

    def set_batch
      @batch = Import::Batch.where(user: current_user).find(params[:id])
    end

    def set_swatch
      @swatch = @batch.discipline&.swatch || Swatch.find_by(name: "app_theme")
    end

    def needs_sheet_selection?
      @batch.sheet_name.blank? && @batch.importer.sheet_names.size > 1
    end

    def setup_sheet_selection_form
      @importer = @batch.importer
      @sheet_names = @importer.sheet_names
    end

    def setup_mapping_form
      @importer = @batch.importer
      preset = Import::MappingPreset.find_by(user: current_user, importer_key: @batch.importer_key)
      @mapper = @importer.column_mapper(preset_mapping: preset&.column_mapping || {})
      @suggested_mapping = @mapper.suggested_mapping
      @disciplines = policy_scope(Discipline).where(project: @batch.project) if @batch.discipline.nil?
    end

    def run_dry_run
      @importer = @batch.importer
      @rows = @importer.dry_run_rows(pundit_user: pundit_user)
    end

    # Where to land the user once this batch is finished with (imported or
    # aborted) - delegates to the importer itself (Import::Base#index_path),
    # since not every model has its own per-model route to build this from
    # (every tagable shares one controller/route instead - see
    # Import::TagableBase#index_path).
    def model_index_path
      @batch.importer.index_path(@batch, self)
    end
  end
end
