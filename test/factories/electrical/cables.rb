# frozen_string_literal: true

FactoryBot.define do
  factory :electrical_cable, class: 'Electrical::Cable' do
    transient do
      tag { nil }
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
    start_mark { nil }
    end_mark { nil }

    # Create tag association in a single transaction
    before(:create) do |cable, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
        if tag.tagable.present?
          raise "Tag is already associated with another record: #{tag.tagable_type}##{tag.tagable_id}"
        end
        cable.tag = tag
      else
        # Create new tag with proper discipline in same transaction
        discipline = Discipline.find_or_create_by(code: cable.class.discipline_code)
        cable.tag = create(:tag, :unique_tag, discipline: discipline)
      end

      # Assign from association if provided
      cable.from = evaluator.from if evaluator.from

      # Assign to association if provided
      cable.to = evaluator.to if evaluator.to
    end
  end
end
