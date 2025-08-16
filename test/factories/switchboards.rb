# frozen_string_literal: true

FactoryBot.define do
  factory :switchboard do
    # Required attributes with sensible defaults
    location { "Main Electrical Room" }
    service { 1 }  # Using enum value, typically 1 for 'Main'
    ingress_protection { "IP65" }
    busbar_rating { 400.0 }  # Amps
    busbar_fault_rating { 25.0 }  # kA
    busbar_fault_duration { 1.0 }  # seconds
    cable_entry { "Bottom" }
    incomer_protection { "630A MCCB" }
    metering { "Main energy meter with CTs" }
    neutral_bar_connections { "100A" }
    earth_bar_connections { "100A" }
    
    # Create a switchboard by building it through a tag
    transient do
      prefix { 'EX' }  # Default prefix for switchboard tags
      sequence(:serial) { |n| n + 1000 }  # Start from 1001
      project { create(:project) }
      discipline { create(:discipline, code: 'E', name: 'Electrical') }
      description { nil }
    end
    
    # This creates a tag with the switchboard as its tagable
    after(:build) do |switchboard, evaluator|
      discipline = evaluator.discipline
      discipline ||= Discipline.find_or_create_by(code: 'E', name: 'Electrical')
      
      tag_attributes = {
        tagable: switchboard,
        prefix: evaluator.prefix,
        serial: evaluator.serial,
        project: evaluator.project,
        discipline: discipline
      }
      
      tag_attributes[:description] = evaluator.description if evaluator.description
      
      switchboard.tag ||= build(:tag, **tag_attributes)
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
