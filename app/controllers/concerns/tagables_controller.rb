module TagablesController
  extend ActiveSupport::Concern

  # Including controllers should explicitly call :set_tag where needed
  # Example: before_action :set_tag, only: [:new, :create, :edit, :update]

  private

  def set_tag
         
    # Handle case when linking to existing tag through tagable_id association first
    if params[:tag_id].present?
      @tag = Tag.find_by(id: params[:tag_id])
      if @tag.nil? || @tag.tagable.present? || 
        (@tag.tagable_type&.present? && @tag.tagable_type != controller_name.classify)
        # Trap case when trying to add a tagable to a tag that is:
        # - not found in the database 
        # - already assigned to a tagable
        # - designated to be assigned to a different class than the calling controller.
        # Workflow should prevent this from being possible through normal use of the application.
        @tag = nil
        return false
      end
    else
      if params[:tag].present?
        # Handle case when creating a new tag
        @tag_invalid = false
        @tag = Tag.new(tag_params)
        
        # Validate the tag - this could be left to the calling resource
        unless @tag.valid?
          # Invalid user submission: return to form with errors
          @tag_invalid = true
        end
      else
        # No tag parameters: new resource
        @tag = Tag.new()
      end
    end
  end

  def tag_params
    params.require(:tag).permit(:project_id, :discipline_id, :prefix, :serial, :suffix, 
                                :service, :stage, :notes, :tagable_id, :tagable_type)
  end
end
