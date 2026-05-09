FactoryBot.define do
  factory :document do
    # Attributes
    association :discipline
    association :doc_type
    serial {  } # serial is generated in the model before validation
    title { "Factory Document" } # Provide default value for required field
    notes { "lorem ipsum dolor sit amet" } 
  end
end