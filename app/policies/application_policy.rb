# frozen_string_literal: true

class ApplicationPolicy
  # Wrapper for pundit user, to include current_project in policies
  class UserContext
    attr_reader :user, :current_project
# The application modifies the behaviour of pundit to include the current project context in policies.
# Most work in the application is scoped to the current project, so the current project is used in most policies.
# This implementation follows the pundit gem documentation guidelines, by overriding the pundit_user method to a 
# UserContext object, which includes the current project.
    def initialize(user, current_project)
      @user = user
      @current_project = current_project
    end
  end

  # Base scope class for policy scopes
  # Provides access to user, current_project, and scope in policy scopes
  class Scope
    attr_reader :user_context, :user, :current_project, :scope

    def initialize(user_context, scope)
      @user_context = user_context
      @user = user_context&.user
      @current_project = user_context&.current_project
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private
    # Only project and discipline instance roles are tested. 
    # Global roles and resource wide roles are not checked.
    def user_has_project_role?(project)
      return false if user.nil?
      return false unless project.present?
      # Check if user has any role on the specified project or its disciplines
      user.roles.where(resource_type: "Discipline").
        where(resource_id: Discipline.where(project: project).select(:id)).exists? ||
      user.roles.where(resource: project).exists?
    end
  end

  attr_reader :user_context, :record, :user, :current_project

  def initialize(user_context, record)
    @user_context = user_context
    @user = user_context&.user
    @current_project = user_context&.current_project
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    false
  end

  def update?
    false
  end

  def edit?
    false
  end

  # Only global admins or app owner can destroy records by default
  # Override in specific policies if different rules are needed
  def destroy?
    user.present? && (user.has_role?(:admin) || user.has_role?(:app_owner))
  end

  private
    # Only project and discipline instance roles are tested. 
    # Global roles and resource wide roles are not checked.
    def user_has_project_role?(project)
      return false if user.nil?
      return false unless project.present?
      # Check if user has any role on the specified project or its disciplines
      user.roles.where(resource_type: "Discipline").
        where(resource_id: Discipline.where(project: project).select(:id)).exists? ||
      user.roles.where(resource: project).exists?
    end

    # Use to find if a user has a required role on any discipline of a project.
    # This allows access to the new form on discipline scoped resources (tags, documents) 
    # before the discipline is known.
    def user_has_a_required_role?(project)
      return false if user.nil? || project.nil?
      user.roles.select { |role| role.resource_type == "Discipline" &&
        role.resource_id.present? &&
        role.resource.project_id == project.id &&
        (role.name.to_s == (role.resource.required_role? ? 
          role.resource.required_role.to_s : 
          "#{role.resource.name}::Base".safe_constantize&.required_role.to_s)
        )
      }.any?
    end

    # Use to find if a user has the required role for a record's discipline.
    def user_is_accredited?(discipline)
      return false if discipline.nil?
      rr = discipline.required_role? ? 
          discipline.required_role.to_s : 
          discipline.class.required_role.to_s
      user.has_role?(rr, discipline) || 
        user.is_admin? || 
        user.is_app_owner? ||
        user.is_project_admin_of?(discipline.project)
    end
end
