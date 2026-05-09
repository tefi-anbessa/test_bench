FactoryBot.define do
  factory :doc_type do
    # Attributes
    association :discipline
    sequence(:code) { |n| "D#{n}" }
    name { 'Standard Operating Procedure' } # Provide default value for required field
    description { "Factory generated document type." }
  end
end
