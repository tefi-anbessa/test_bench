module CurrentProjectConcern
  extend ActiveSupport::Concern

  included do
    helper_method :set_current_project
    helper_method :current_project
    helper_method :project_selected?
    
    private
    
    def set_current_project(project)
      if project
        @current_project = project
        session[:project_id] = project.id
        cookies.signed[:project_id] = project.id
      else
        @current_project = nil
        session.delete(:project_id)
        cookies.delete(:project_id)
        
      end
    end

    # Returns the current project from cookie or session
    def current_project
      @current_project ||= load_current_project
    end
    
    # Check if a project is selected
    def project_selected?
      current_project.present?
    end
    
    # Load project from session or cookie
    def load_current_project
      project_id = session[:project_id].to_i || cookies.signed[:project_id].to_i 
      Project.find_by(id: project_id) if project_id.present?
    end
    
    # Require a project to be selected
    def require_project!
      return if project_selected?
      # debugger
      store_location_for_project(request.fullpath) if request.get?
      redirect_to select_projects_path, alert: 'Please select a project to continue.' #TODO: internationalize
    end
    
    # Store location for project navigation
    def store_location_for_project(location)
      session[:project_return_to] = location
    end
    
    # Get stored project location
    def stored_location_for_project
      session.delete(:project_return_to)
    end
    
    # Clear stored project location
    def clear_stored_location_for_project
      session.delete(:project_return_to)
    end
  end
end
