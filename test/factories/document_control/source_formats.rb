FactoryBot.define do
  factory :document_control_source_format, class: DocumentControl::SourceFormat do
    # Attributes
    vendor { "Open Source" }
    title { "Test Source Format" } 
    file_extension { ".pdf" } 
    revision { "1.0" } 
    notes { "Test notes" }
  end
end
