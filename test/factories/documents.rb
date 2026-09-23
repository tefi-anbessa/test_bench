FactoryBot.define do
  factory :document do
    # Attributes
    association :discipline
    association :doc_type
    serial {  } # serial is generated in the model before validation
    title { Faker::Book.title } # Provide default value for required field
    notes { Faker::Lorem.paragraph(sentence_count: 1) } 
  end
end