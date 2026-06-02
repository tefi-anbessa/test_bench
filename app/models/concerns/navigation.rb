# app/models/concerns/navigation.rb
module Navigation
  extend ActiveSupport::Concern

  def next
    navigator.window[:next]
  end

  def prev
    navigator.window[:prev]
  end

  def window
    navigator.window
  end

  private

  def navigator
    @navigator ||= Navigator.new(
      scope: self.class.policy_scope(self.class),
      record: self,
      order: ordering.clauses
    )
  end

  def ordering
    raise NotImplementedError
  end
end