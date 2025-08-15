class ProjectPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  attr_reader :user, :project

  def initialize(user, project)
    @user = user
    @project = project
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    user.is_owner?
  end

  def create?
    user.is_owner?
  end

  def update?
    edit?
  end

  def edit?
    user.is_owner? || user.is_admin?
  end

  def destroy?
    user.is_owner?
  end


  class Scope < ApplicationPolicy::Scope
    # Any project for which the user has a role can be listed.
    def resolve
      if user.is_owner? || user.is_admin? ||
        user.roles.where(resource_type: "Project", resource_id: nil).count > 0
        # If user has global admin role, or any resource role on Projects,
        # scope includes all.
        Project.all
      else
        # Scope includes the projects where user has any resource specific role
        Project.where(:id => user.roles.where(resource_type: "Project")
                        .pluck(:resource_id)).unique
      end
    end
  end
end
