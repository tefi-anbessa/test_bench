FactoryBot.define do
  factory :source_format do
    vendor { "Open Source" }
    title { "Test Source Format" } 
    file_extension { ".pdf" } 
    
    sequence(:revision) { |n| "1.#{n}" }
    
    notes { "Test notes" }
  end
end
