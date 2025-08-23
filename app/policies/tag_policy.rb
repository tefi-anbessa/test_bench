class TagPolicy < ApplicationPolicy
  def tag
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.is_app_owner? || user&.has_role?(:admin)
        scope.all
      elsif user.present? && current_project.present? && user_has_project_role?
        # Users can see tags in projects where they have a role
        scope.where(project: current_project)
      else
        scope.none
      end
    end

    private

    def user_has_project_role?
      user.roles
          .where(resource: current_project)
          .exists?
    end
  end

  def index?
    # Anyone can view the tags index (actual tags are filtered by scope)
    true
  end

  def show?
    # Only show tag if user has access to its project
    return false unless record.present? && record.project.present?
    
    # Check if user has any role on the project
    return true if user&.is_app_owner? || user&.has_role?(:admin)
    
    # Check if user has a role on the project
    user_has_project_role?(record.project)
  end

  def new?
    create?
  end

  def create?
    # Any user with a role on the project can create tags
    project_policy.show? && user_has_project_role?
  end

  def edit?
    update?
  end

  def update?
    # Any user with a role on the project can update tags
    project_policy.show? && user_has_project_role?
  end

  def destroy?
    # Default to admin-only for destroy, as per application policy
    user&.has_role?(:admin) || user&.is_app_owner?
  end

  private

  def project_policy
    @project_policy ||= ProjectPolicy.new(user_context, tag&.project || current_project)
  end

  def user_has_project_role?(project = nil)
    project ||= current_project
    return false if user.nil? || project.nil?
    
    # Check if user has any role on the specified project
    user.roles
        .where(resource_type: 'Project', resource_id: project.id)
        .exists?
  end
end
