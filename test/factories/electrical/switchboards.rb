# frozen_string_literal: true

FactoryBot.define do
  factory :electrical_switchboard, class: 'Electrical::Switchboard' do
    # Tag can be passed explicitly, if not tag will be created.
    # If discipline is passed, tag will be created on that discipline.
    # Otherwise, tag will be created on a new project with "Electrical" discipline.
    transient do
      tag { nil }
      discipline { nil }
    end
    # Default required attributes
    voltage_rating { '600/1000V' }  # Required field - use common voltage rating
    busbar_rating { 400 }           # Required field - common busbar rating in Amps
    busbar_fault_duration { 0.5 }
    cable_entry { "Bottom" }
    incomer_protection { "Isolator 4P"}
    metering { "None"}
    neutral_bar_connections { "10 x 4mm²"}
    earth_bar_connections { "10 x 4mm²"}
    ingress_protection { "IP44"}
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    # Create tag association in a single transaction
    before(:create) do |switchboard, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        if evaluator.tag.tagable.present?
          raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
        end
        switchboard.tag = evaluator.tag
      else
        # Create new tag with proper discipline in same transaction
        if evaluator.discipline
          # Create tag on the provided discipline
          switchboard.tag = create(:tag, :unique_tag, discipline: evaluator.discipline)
        else
          # Create project with auto-created disciplines
          project = create(:project)
          discipline = project.disciplines.find_by(name: switchboard.class.module_parent_name) ||
               create(:discipline, name: switchboard.class.module_parent_name, project: project)
          switchboard.tag = create(:tag, :unique_tag, discipline: discipline)
        end
      end
    end

    trait :with_circuits do
      transient do
        circuits_count { 3 }  # Default to 3 circuits, can be overridden
      end

      after(:create) do |switchboard, evaluator|
        # Create circuits with this switchboard
        evaluator.circuits_count.times do |i|
          create(:electrical_circuit, electrical_switchboard: switchboard, serial: i + 1)
        end
      end
    end
  end
end
