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

  def update?
    user.is_owner? || user.is_admin?
  end

  def create?
    user.is_owner?
  end

  def destroy?
    user.is_owner?
  end

  def edit?
    user.is_owner? || user.is_admin?
  end


  class Scope < ApplicationPolicy::Scope
    # Any project for which the user has a role can be listed.
    def resolve
      scope.with_roles([:reader, :author, :editor, :checker, :approver, :admin, :owner], user)
    end
  end
end
