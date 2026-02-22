class SwatchPolicy < ApplicationPolicy
    
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    user&.is_admin? || user&.is_app_owner?
  end

  def create?
    new?
  end

  def edit?
    user&.is_admin? || user&.is_app_owner?
  end

  def update?
    edit?
  end

  def destroy?
    user&.is_app_owner?
  end
end