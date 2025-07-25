class CablePolicy < ApplicationPolicy
  attr_reader :user, :cable

  def initialize(user, cable)
    @user = user
    @cable = cable
  end

  def index?
    can_read?(@user, @cable)
  end

  def show?
    can_read?(@user, @cable)
  end

  def update?
    can_edit?(@user, @cable)
  end

  def create?
    can_create?(@user, @cable)
  end

  def destroy?
    can_create?(@user, @cable)
  end

  def edit?
    can_edit?(@user, @cable)
  end


  class Scope < ApplicationPolicy::Scope
    # Any cable for which the user has a role can be listed.
    def resolve
      scope.with_roles([:reader, :author, :editor, :checker, :approver, :admin, :owner], user)
    end
  end
end
