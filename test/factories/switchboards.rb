# frozen_string_literal: true

FactoryBot.define do
  factory :switchboard do
    # Require tag to be provided
    tag

    # Trait to create a new tag with default switchboard settings
    trait :with_tag do
      transient do
        prefix { 'EX' }
        project { create(:project) }
        discipline { Discipline.find_or_create_by(code: 'E') { |d| d.name = 'Electrical Engineering' } }
        description { nil }
      end

      after(:build) do |switchboard, evaluator|
        switchboard.tag = build(
          :tag,
          :unique_tag,
          tagable: switchboard,
          prefix: evaluator.prefix,
          project: evaluator.project,
          discipline: evaluator.discipline,
          description: evaluator.description
        )
      end
    end
    
    # Traits for different types of switchboards
    trait :main_switchboard do
      location { "Main Switch Room" }
      service { 1 }  # Main
      ingress_protection { "IP31" }
      busbar_rating { 1200.0 }
      busbar_fault_rating { 50.0 }
      description { "Main LV Switchboard" }
    end
    
    trait :sub_switchboard do
      location { "Plant Room" }
      service { 2 }  # Sub-main
      ingress_protection { "IP55" }
      busbar_rating { 250.0 }
      busbar_fault_rating { 25.0 }
      description { "Sub-main Distribution Board" }
    end
    
    trait :with_circuits do
      transient do
        circuits_count { 3 }  # Default to 3 circuits, can be overridden
      end
      
      after(:create) do |switchboard, evaluator|
        create_list(:circuit, evaluator.circuits_count, switchboard: switchboard)
      end
    end
  end
end
