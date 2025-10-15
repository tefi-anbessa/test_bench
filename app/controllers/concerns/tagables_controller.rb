module TagablesController
  extend ActiveSupport::Concern

  # Including controllers should explicitly call :set_tag where needed

  private

  def tag_params
    # Get the tag parameters from the nested structure
    tag_source = if params[controller_name.singularize.to_sym].present?
                   params[controller_name.singularize.to_sym][:tag] || {}
                 else
                   params[:tag] || {}
                 end
  
    # If tag_source is already an ActionController::Parameters, use it directly
    # Otherwise, convert it to ActionController::Parameters
    tag_params = tag_source.is_a?(ActionController::Parameters) ? 
                 tag_source : 
                 ActionController::Parameters.new(tag_source)
  
    # Permitted parameters
    tag_params.permit(
      :project_id, :discipline_id, :prefix, :serial, :suffix, 
      :service, :stage, :notes, :tagable_id, :tagable_type
    )
  end

    def setup_tag_form
      @projects = policy_scope(Project)
      @disciplines = Discipline.all.select(:id, :code, :name).to_a
    end

    def set_tag

      # Rails.logger.info "tag_params: #{tag_params}"
      # Handle case when linking to existing tag through tagable_id association first
      # Uses shallow nested route
      if params[:tag_id].present?
        @tag = Tag.find_by(id: params[:tag_id])
        if @tag.nil?
          # Tag not found in database
          @tag = Tag.new
          @tag.errors.add(:base, :tag_not_found)
          return false
        elsif @tag.tagable.present?
          # Tag already assigned to a tagable
          @tag = Tag.new  
          @tag.errors.add(:base, :tag_already_assigned)
          return false
        elsif @tag.tagable_type&.present? && @tag.tagable_type != controller_name.classify
          # Tag designated for different controller type
          @tag = Tag.new
          @tag.errors.add(:base, :tagable_type_mismatch)
          return false
        end
      else
        if tag_params.present?
          # Handle case with tag parameters
          @tag = Tag.new(tag_params)
        else
          # No tag parameters: new resource
          @tag = Tag.new()
        end
      end
    end
end
