
module ErrorsHelper
  # The HAL 9000 image shown on the custom error pages. alt text names the
  # status code, not "HAL 9000" - a screen reader user gets no information
  # from the film reference, only from the error itself. Falls back to no
  # image rather than an external URL - an error page shouldn't depend on
  # a third-party fetch succeeding.
  def error_image(name, status_code, max_width: 600)
    image_tag(name, class: 'img-fluid mb-4', alt: "Error #{status_code}", style: "max-width: #{max_width}px;")
  rescue StandardError
    ''
  end

  def trap_forbidden
    respond_to do |format|
      format.html { render 'errors/forbidden', status: :forbidden }
      # format.any  { head :forbidden }  # Simple response for non-HTML formats
    end
    return false
  end
end