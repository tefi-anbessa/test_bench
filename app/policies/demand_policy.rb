class DemandPolicy < ElectricalResourcePolicy
  # Returns the demand record
  def demand
    record
  end
  
  # Get the demandable object (Motor, LightCct, etc.)
  def demandable
    demand.demandable
  end
  
  # Override tag method to use demandable's tag association
  def tag
    demandable&.tag
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
        return scope.none unless current_project
      
        # First, get all taggable IDs from the current project
        taggable_ids = current_project.tags.pluck(:tagable_type, :tagable_id)
        return scope.none if taggable_ids.empty?
      
        # Convert to a hash of { type => [ids] }
        type_to_ids = taggable_ids.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(type, id), hash|
          hash[type] << id
        end
      
        # Build a single query with OR conditions for each type
        query = type_to_ids.map do |type, ids|
          scope.where(demandable_type: type, demandable_id: ids)
        end.reduce(:or) || scope.none
      
        # Execute the combined query
        query
      end
  end
  

  def show?
    return true if user&.is_admin? || user&.is_app_owner?
    return false unless user && current_project && record
    user_has_project_role? && record.demandable.tag.project == current_project
  end

  # Inherit all other behavior from ElectricalResourcePolicy
end
