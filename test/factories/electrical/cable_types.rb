# frozen_string_literal: true
FactoryBot.define do
  factory :electrical_cable_type, class: 'Electrical::CableType' do
    # The bare :discipline factory's default has no registry code/module,
    # so Cable.discipline_available? (and anything else checking
    # discipline.cable_type_class) would always reject it - default to a
    # real, registry-backed Electrical discipline instead.
    discipline { create(:project).disciplines.find_by(code: "E") }
    
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
