module SessionsHelper

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def current_project
    if project = session[:project_id]
      @current_project = Project.find(project)
    end
  end
end
