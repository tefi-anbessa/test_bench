# frozen_string_literal: true

FactoryBot.define do
  factory :electrical_cable, class: 'Electrical::Cable' do
    transient do
      tag { nil }
      discipline { nil }
      cable_type { nil }
      from { nil }  # Source object (Circuit, Switchboard, etc.)
      to { nil }    # Destination object (Demand, Motor, etc.)
    end

    # Required attributes - override with cable_type: your_type if needed
    electrical_cable_type {
      create(:electrical_cable_type,
        notes: "Test Cable Type #{SecureRandom.hex(4)}",
        csa: 1.0
      )
    }

    # Optional attributes
    route_length { 10 }  # meters
    vertical_allowance { 6 }  # meters
    termination_allowance { 4 }  # meters per end
    start_mark { 1001 }
    end_mark { 1010 }

    # Handle from/to associations for both build and create
    after(:build) do |cable, evaluator|
      cable.from = evaluator.from if evaluator.from
      cable.to = evaluator.to if evaluator.to
    end

    # Create tag association in a single transaction
    before(:create) do |cable, evaluator|
      # Determine cable_type - either provided or create one
      cable_type = evaluator.cable_type || cable.electrical_cable_type

      # Handle tag creation
      if evaluator.tag
        tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
        if tag.tagable.present?
          raise "Tag is already associated with another record: #{tag.tagable_type}##{tag.tagable_id}"
        end
        # Validate project match if cable_type provided
        if evaluator.cable_type && tag.discipline&.project != cable_type.project
          raise "Tag's project does not match cable_type's project"
        end
        cable.tag = tag
      else
        # Create new tag with proper discipline in same transaction
        if evaluator.discipline
          # Validate project match if cable_type provided
          if evaluator.cable_type && evaluator.discipline.project != cable_type.project
            raise "Discipline's project does not match cable_type's project"
          end
          cable.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Use cable_type's project or create new project
          project = cable_type&.project || create(:project)
          discipline = project.disciplines.find_by(name: cable.class.module_parent_name) ||
               create(:discipline, name: cable.class.module_parent_name, project: project)
          cable.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
