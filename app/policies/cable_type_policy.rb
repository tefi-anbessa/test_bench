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
    # Only allow if user is present and has a current project
    user.present? && current_project.present?
  end

  def show?
    # Can view if the cable type belongs to the current project
    return false unless user && current_project && cable_type
    cable_type.project == current_project
  end
  
  def new?
    create?
  end
  
  def create?
    # Only electrical designers in the project can create cable types
    return false if user.nil? || current_project.nil?
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
    # Only electrical designers in the project can update cable types
    return false if user.nil? || current_project.nil?
    return false if record.is_a?(Class)  # Don't allow class-level updates
    return false unless cable_type.project == current_project
    user.has_role?(:electrical_designer) && user.has_role?(:team_member, current_project)
  end
  
  def destroy?
    # Only global admin or app owner can destroy
    return false unless user
    user.has_role?(:admin) || user.has_role?(:app_owner)
  end

  private
  
  def electrical_designer_with_access?
    return false unless current_project
    
    (user.has_role?(:electrical_designer, current_project) || 
     user.has_role?(:electrical_designer)) &&
    user.has_role?(:team_member, current_project)
  end

end
