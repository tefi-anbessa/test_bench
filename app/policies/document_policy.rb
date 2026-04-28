# frozen_string_literal: true
class DocumentPolicy < DisciplineResourcePolicy
  # Returns the resource record
  def document
    record
  end

  # Inherit all actions from DisciplineResourcePolicy
end
