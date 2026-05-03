class AddConstructionToElectricalCableTypes < ActiveRecord::Migration[8.0]
  def up
    add_column :electrical_cable_types, :construction, :integer
    add_reference :electrical_cable_types, :discipline, null: true, foreign_key: true
    rename_column :electrical_cable_types, :cores, :groups

    # Assign Electrical discipline to existing cable types
    Electrical::CableType.find_each do |ct|
      electrical = ct.project.disciplines.find_by(name: "Electrical")
      ct.update_column(:discipline_id, electrical.id)
    end

    # Now make discipline required
    change_column_null :electrical_cable_types, :discipline_id, false

    # Remove project_id (replaced by discipline relationship)
    remove_reference :electrical_cable_types, :project, foreign_key: true
  end

  def down
    # Restore project_id from discipline
    add_reference :electrical_cable_types, :project, foreign_key: true
    rename_column :electrical_cable_types, :groups, :cores
    Electrical::CableType.find_each do |ct|
      ct.update_column(:project_id, ct.discipline&.project_id)
    end

    remove_reference :electrical_cable_types, :discipline, foreign_key: true
    remove_column :electrical_cable_types, :construction
  end
end
