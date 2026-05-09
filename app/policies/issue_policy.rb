# frozen_string_literal: true

class IssuePolicy < DisciplineResourcePolicy
  # Returns the resource record
  def issue
    record
  end

  # Use DocumentPolicy scope for issues
  class Scope < DocumentPolicy::Scope
  end
end
