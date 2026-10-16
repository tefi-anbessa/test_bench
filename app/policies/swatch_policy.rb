class SwatchPolicy < ApplicationPolicy
    
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Protect against url injection
    return false if user.nil?
    true
  end

  def show?
    # Protect against url injection
    return false if user.nil?
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