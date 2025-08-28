class CableTypePolicy < ApplicationPolicy
  def cable_type
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless @current_project
      scope.where(project: @current_project)
    end
  end

  def index?
    # Only allow if user is present and current project is set.
    user.present? && current_project.present?
  end

  def show?
    # Admin and app_owner can view anything
    return true if user&.is_admin? || user&.is_app_owner?
    
    # Others can only view if the cable type belongs to the current project
    return false unless user && current_project && cable_type
    cable_type.project == current_project
  end
  
  def new?
    create?
  end
  
  def create?
    return false if user.nil? || current_project.nil?

    # Admin and app_owner can create
    return true if user.is_admin? || user.is_app_owner?
    
    # Other than admins, only electrical designers in the project can create cable types
    
    # Allow class-level checks for create? and new? actions
    return user.has_role?(:electrical_designer) && user.has_role?(:team_member, current_project) if record.is_a?(Class)
    
    # For instance-level checks, also verify the project matches
    cable_type.project == current_project &&
      user.has_role?(:electrical_designer) && 
      user.has_role?(:team_member, current_project)
  end
  
  def edit?
    update?
  end
  
  def update?
    # Admin and app_owner can do anything
    return true if user.is_admin? || user.is_app_owner?
    
    # Only electrical designers in the project can update cable types
    return false if user.nil? || current_project.nil?
    return false if record.is_a?(Class)  # Don't allow class-level updates
    return false unless cable_type.project == current_project
    
    user.has_role?(:electrical_designer) && user.has_role?(:team_member, current_project)
  end
  
  def destroy?
    # Admin and app_owner can do anything
    return true if user.is_admin? || user.is_app_owner?
    
    # No one else can delete cable types
    false
  end

  private
  
  def electrical_designer_with_access?
    return false unless current_project
    
    (user.has_role?(:electrical_designer, current_project) || 
     user.has_role?(:electrical_designer)) &&
    user.has_role?(:team_member, current_project)
  end

end
