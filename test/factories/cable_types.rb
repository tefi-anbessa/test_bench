# frozen_string_literal: true
FactoryBot.define do
  # Shared CableType, with an Electrical::CableTypeDetail - named for the
  # detail flavour it builds, same as :electrical_switchboard etc. name
  # the module even though what they return (and what CableType itself
  # always is) is a plain class.
  factory :electrical_cable_type, class: 'CableType' do
    # The bare :discipline factory's default has no registry code/module,
    # so Cable.discipline_available? (and anything else checking
    # discipline.cable_type_detail_class) would always reject it - default
    # to a real, registry-backed Electrical discipline instead.
    discipline { create(:project).disciplines.find_by(code: "E") }

    primary_role { :power_distribution }
    groups { 3 }
    construction { 'core' }
    conductor_material { 'Cu' }
    csa { 2.5 }

    insulation { 'XLPE' }
    bedding { 'PVC' }
    armour { 'SWA' }
    sheath { 'PVC' }
    temperature_rating { '75˚C' }
    voltage_rating { '450/750V' }
    fire_protection { :standard }
    bedding_od { 10.0 }
    overall_od { 12.0 }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    transient do
      neutral_csa { 2.5 }
      earth_csa { 1.5 }
    end

    after(:build) do |cable_type, evaluator|
      cable_type.detail ||= Electrical::CableTypeDetail.new(
        neutral_csa: evaluator.neutral_csa, earth_csa: evaluator.earth_csa
      )
    end
  end

  factory :instrument_cable_type, class: 'CableType' do
    discipline { create(:project).disciplines.find_by(code: "J") }

    primary_role { :analog_signal }
    groups { 2 }
    construction { 'pair' }
    conductor_material { 'Cu' }
    csa { 0.75 }

    insulation { 'PVC' }
    sheath { 'PVC' }
    temperature_rating { '60˚C' }
    voltage_rating { '50/120V' }
    fire_protection { :standard }
    overall_od { 6.0 }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    transient do
      individual_screen { true }
      overall_screen { false }
      twist_pitch { 25.0 }
    end

    after(:build) do |cable_type, evaluator|
      cable_type.detail ||= Instrument::CableTypeDetail.new(
        individual_screen: evaluator.individual_screen,
        overall_screen: evaluator.overall_screen,
        twist_pitch: evaluator.twist_pitch
      )
    end
  end

  # Alias matching CableType's own bare model name, for shared test
  # helpers that build a resource from resource_class.model_name.param_key
  # (e.g. DisciplineModelTests, ControllerTestHelper) - defaults to the
  # Electrical flavour, the longest-established one.
  factory :cable_type, parent: :electrical_cable_type
end
