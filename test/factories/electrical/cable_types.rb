# frozen_string_literal: true
FactoryBot.define do
  factory :electrical_cable_type, class: 'Electrical::CableType' do
    discipline { association :discipline } 
    
    # Required fields
    groups { 3 }
    construction { 'core' }
    conductor_material { 'Cu' }
    csa { 2.5 }
    
    # Optional fields with sensible defaults
    neutral_csa { 2.5 }
    earth_csa { 1.5 }
    insulation { 'XLPE' }
    bedding { 'PVC' }
    armour { 'SWA' }
    sheath { 'PVC' }
    temperature_rating { '75˚C' }
    voltage_rating { '450/750V' }
    bedding_od { 10.0 }
    overall_od { 12.0 }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }
  end
end
