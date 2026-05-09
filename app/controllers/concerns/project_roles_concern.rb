# frozen_string_literal: true

module ProjectRolesConcern
  extend ActiveSupport::Concern

  # Collects all roles on the project and its child disciplines
  # Returns a single collection of all project-related roles
  def project_roles(project)
    project_roles = Role.where(resource: project)
    discipline_roles = Role.where(resource_type: 'Discipline', resource_id: project.discipline_ids)
    
    project_roles.or(discipline_roles)
  end

  # Gets all users with any role on the project or its disciplines
  def users_with_project_roles(project)
    User.joins(:roles)
        .where(roles: { id: project_roles(project).select(:id) })
        .select('users.*, roles.name as role_name, roles.resource_type, roles.resource_id')
        .distinct
        .order(:name)
  end

  # Checks if user has any instance role on the project or its disciplines
  def user_has_project_access?(user, project)
    user.roles.exists?(resource: project) || user.roles.exists?(resource_id: project.discipline_ids)
  end
end
