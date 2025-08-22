# frozen_string_literal: true

class ApplicationPolicy
  # Wrapper for pundit user, to include current_project in policies
  class UserContext
    attr_reader :user, :current_project

    def initialize(user, current_project)
      @user = user
      @current_project = current_project
    end
  end

  class Scope
    attr_reader :user_context, :user, :scope, :current_project

    def initialize(user_context, scope)
      @user_context = user_context
      @user = user_context&.user
      @current_project = user_context&.current_project
      @scope = scope
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
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  # Only global admins or app owner can destroy records by default
  # Override in specific policies if different rules are needed
  def destroy?
    user.has_role?(:admin) || user.has_role?(:app_owner)
  end

  class Scope
    def initialize(user_context, scope)
      @user = user_context.user
      @current_project = user_context.current_project
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

  end

  private
    def can_read?(user, record)
      user.has_any_role? :owner, :admin, {name: :reader, resource: record},
                                          {name: :creator, resource: record},
                                          {name: :editor, resource: record},
                                          {name: :checker, resource: record},
                                          {name: :approver, resource: record}
    end

    def can_edit?(user, record)
      user.has_any_role? :owner, :admin, {name: :creator, resource: record},
                                          {name: :editor, resource: record},
                                          {name: :checker, resource: record},
                                          {name: :approver, resource: record}
    end

    def can_create?(user, record)
      user.has_any_role? :owner, :admin, {name: :creator, resource: record}
    end
end
