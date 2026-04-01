FactoryBot.define do
  factory :document_control_doc_type, class: DocumentControl::DocType do
    # Attributes
    association :discipline
    code { 'SOP' } # Provide default value for required field
    label { 'Standard Operating Procedure' } # Provide default value for required field
    description { "Factory generated document type." } 
    
  end
end
