# frozen_string_literal: true

FactoryBot.define do
  # Create a tag first, then build/associate the cable with it
  # Usage:
  #   1. Create a tag first: tag = create(:tag, prefix: 'EC', serial: 1001, project: project)
  #   2. Then create cable: cable = create(:cable, tag: tag)
  #
  # Or use the :with_tag trait for a one-liner:
  #   cable = create(:cable, :with_tag, project: project)
  #
  factory :electrical_cable, class: 'Electrical::Cable' do
    transient do
      # Tag can be passed explicitly or will be auto-created
      tag { nil }

      # Project and discipline can be passed or will use defaults
      project { nil }      # Will create default if not provided
      discipline { nil }   # Will create default if not provided

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

    # This callback runs after build but before validation/creation
    after(:build) do |cable, evaluator|

    # Handle tag assignment
    if evaluator.tag
      # Tag was explicitly provided
      tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
      raise "Tag is already associated with another record" if tag.tagable.present?
      cable.tag = tag
    else
      # Auto-create tag using provided or default project and discipline
      project = evaluator.project || create(:project)
      discipline = evaluator.discipline || create(:discipline, :elec)

      cable.tag = create(:tag,
        prefix: 'EC',
        project: project,
        discipline: discipline,
        tagable_type: 'Electrical::Cable',
        tagable_id: cable.id
      )
    end

      # Assign from association if provided
      if evaluator.from
        cable.from = evaluator.from
      end

      # Assign to association if provided
      if evaluator.to
        cable.to = evaluator.to
      end
    end
  end
end
