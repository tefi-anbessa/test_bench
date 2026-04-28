
FactoryBot.define do
  factory :document_control_source_format, class: DocumentControl::SourceFormat do
    vendor { "Open Source" }
    title { "Test Source Format" } 
    file_extension { ".pdf" } 
    
    sequence(:revision) { |n| "1.#{n}" }
    
    notes { "Test notes" }
  end
end
