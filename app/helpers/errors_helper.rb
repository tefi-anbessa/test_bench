
module ErrorsHelper
  def trap_forbidden
    respond_to do |format|
      format.html { render 'errors/forbidden', status: :forbidden }
      # format.any  { head :forbidden }  # Simple response for non-HTML formats
    end
    return false
  end
end