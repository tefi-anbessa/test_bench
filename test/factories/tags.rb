FactoryBot.define do
  factory :tag do
    sequence(:prefix) { |n| ("A".ord + (n % 26)).chr }  # Generates A, B, C, etc.
    sequence(:serial) { |n| n % 1000 }  # Sequential numbers
    suffix { "" }
    description { "Test Tag" }
    stage { 0 }
    notes { nil }
    
    association :project
    association :discipline
    
    trait :with_suffix do
      sequence(:suffix) { |n| "%03d" % n }  # Zero-padded 3-digit numbers
    end
    
    trait :with_stage do
      stage { rand(1..10) }  # Random stage between 1 and 10
    end
    
    trait :with_notes do
      notes { Faker::Lorem.paragraph(sentence_count: 2) }
    end
    
    trait :cable do
      prefix { 'C' }
      description { 'Cable Tag' }
      association :discipline, :c
    end
    
    trait :electrical do
      prefix { 'E' }
      description { 'Electrical Tag' }
      association :discipline, :e
    end
    
    trait :mechanical do
      prefix { 'M' }
      description { 'Mechanical Tag' }
      association :discipline, :m
    end
    
    trait :complete do
      with_suffix
      with_stage
      with_notes
    end
    
    trait :sequential do
      sequence(:serial) { |n| n }
      with_suffix
    end
    
    # Factory for creating tags in sequence (e.g., C-001, C-002, etc.)
    factory :sequential_tag do
      sequence(:serial) { |n| n }
      with_suffix
    end
    
    # Factory for creating a full tag with all attributes
    factory :complete_tag do
      with_suffix
      with_stage
      with_notes
    end
  end
end
