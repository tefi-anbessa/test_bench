# frozen_string_literal: true

FactoryBot.define do
  factory :electrical_cable, class: 'Electrical::Cable' do
    transient do
      tag { nil }
      discipline { nil }
      cable_type { nil }
      from { nil }  # Source object (Circuit, Switchboard, etc.)
      to { nil }    # Destination object (Demand, Motor, etc.)
      cable_type_attributes { {} }
    end

    # Required attributes - set in after(:build) to avoid inline create
    electrical_cable_type { nil }

    # Optional attributes
    route_length { 10 }  # meters
    vertical_allowance { 6 }  # meters
    termination_allowance { 4 }  # meters per end
    start_mark { 1001 }
    end_mark { 1010 }

    # Handle associations for both build and create
    after(:build) do |cable, evaluator|
      # Set from/to associations
      cable.from = evaluator.from if evaluator.from
      cable.to = evaluator.to if evaluator.to

      # Create cable_type if not provided
      unless cable.electrical_cable_type
        cable.electrical_cable_type = evaluator.cable_type ||
          build(:electrical_cable_type, evaluator.cable_type_attributes)
      end

      # Create tag if not provided
      unless cable.tag
        if evaluator.tag
          tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
          if tag.tagable.present?
            raise "Tag is already associated with another record: #{tag.tagable_type}##{tag.tagable_id}"
          end
          cable.tag = tag
        elsif evaluator.discipline
          cable.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          cable_type = cable.electrical_cable_type
          project = cable_type&.discipline&.project || create(:project)
          discipline = project.disciplines.find_by(name: cable.class.module_parent_name) ||
               create(:discipline, name: cable.class.module_parent_name, project: project)
          cable.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end
  end
end
