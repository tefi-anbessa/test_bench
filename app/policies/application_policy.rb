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
    # Global roles count as having a role on whichever project is given,
    # without needing an actual Role row - but a project must still be
    # given; this never returns true for a nil project, even for admins.
    # Only project and discipline instance roles are tested beyond that.
    # Resource wide roles are not checked.
    def user_has_project_role?(project)
      return false if user.nil?
      return false unless project.present?
      return true if user.is_admin? || user.is_app_owner?
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
    # Global roles count as having a role on whichever project is given,
    # without needing an actual Role row - but a project must still be
    # given; this never returns true for a nil project, even for admins.
    # Only project and discipline instance roles are tested beyond that.
    # Resource wide roles are not checked.
    def user_has_project_role?(project)
      return false if user.nil?
      return false unless project.present?
      return true if user.is_admin? || user.is_app_owner?
      # Check if user has any role on the specified project or its disciplines
      user.roles.where(resource_type: "Discipline").
        where(resource_id: Discipline.where(project: project).select(:id)).exists? ||
      user.roles.where(resource: project).exists?
    end
end
