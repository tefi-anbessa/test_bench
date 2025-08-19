class MakeProjectRequiredForCableTypes < ActiveRecord::Migration[7.0]
  def up
    # First, ensure there are no null project_ids
    CableType.where(project_id: nil).each do |cable_type|
      # Assign to the first project or raise an error if none exists
      project = Project.first
      raise "No projects exist. Please create a project first." unless project
      cable_type.update!(project: project)
    end

    # Then add the not null constraint
    change_column_null :cable_types, :project_id, false
  end

  def down
    # Remove the not null constraint
    change_column_null :cable_types, :project_id, true
  end
end
