class TagPolicy < ApplicationPolicy

  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  def index?
    can_read?(user)
  end

  def show?
    can_read?(user)
  end

  def update?
    can_edit?(user)
  end

  def create?
    can_create?(user)
  end

  def destroy?
    can_create?(user)
  end

  def edit?
    can_edit?(user)
  end

  private
    def can_read?(user)
      user.has_any_role? :owner, :admin, {name: :reader, resource: Tag},
                                          {name: :creator, resource: Tag},
                                          {name: :editor, resource: Tag},
                                          {name: :checker, resource: Tag},
                                          {name: :approver, resource: Tag}
    end

    def can_edit?(user)
      user.has_any_role? :owner, :admin, {name: :creator, resource: Tag},
                                          {name: :editor, resource: Tag},
                                          {name: :checker, resource: Tag},
                                          {name: :approver, resource: Tag}
    end

    def can_create?(user)
      user.has_any_role? :owner, :admin, {name: :creator, resource: Tag}
    end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
