# frozen_string_literal: true

FactoryBot.define do
  factory :cable_type do
    # Required association
    project
    
    conductor_material { 'Copper' }
    conductor_makeup { '2C+E' }  # Required field
    csa { 4.0 }  # Cross-sectional area in mm²
    neutral_csa { 4.0 }
    earth_csa { 2.5 }
    insulation { 'PVC' }
    bedding { 'PVC' }
    armour { 'GSWA' }  # Galvanized Steel Wire Armour
    sheath { 'XLPE/nylon' }
    bedding_od { 10.5 }  # Outer diameter in mm
    overall_od { 12.5 }  # Overall diameter in mm
    temperature_rating { 1 }  # Using enum value, typically 70°C for PVC

    # Traits for common cable types
    trait :pvc_flat_twin_earth do
      conductor_makeup { '2C+E' }
      csa { 1.5 }
      description { 'Flat Twin & Earth Cable' }
      insulation { 'PVC' }
      sheath { 'PVC' }
      armour { nil }
    end

    trait :swa do
      conductor_makeup { '3C+E' }
      csa { 6.0 }
      description { 'Steel Wire Armoured Cable' }
      insulation { 'XLPE' }
      bedding { 'PVC' }
      armour { 'GSWA' }
      sheath { 'PVC' }
    end

    # For testing invalid records
    trait :invalid do
      conductor_makeup { nil }
    end
  end
end
