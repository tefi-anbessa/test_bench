FactoryBot.define do
  factory :document do
    # Transient - lets callers pass discipline: directly (matching every
    # other discipline-resource factory, and what the shared
    # setup_discipline_resources test helper always passes) even though
    # Document itself has no writable discipline - it's derived through
    # doc_type. Builds a matching doc_type and sets creation_discipline so
    # #discipline/#project resolve correctly even for an unsaved (:build
    # strategy) document, where doc_type itself may also still be unsaved.
    transient do
      discipline { nil }
    end

    doc_type { discipline ? association(:doc_type, discipline: discipline) : association(:doc_type) }
    serial {  } # serial is generated in the model before validation
    title { Faker::Book.title } # Provide default value for required field
    notes { Faker::Lorem.paragraph(sentence_count: 1) }

    after(:build) do |document, evaluator|
      document.creation_discipline = evaluator.discipline if evaluator.discipline
    end
  end
end
