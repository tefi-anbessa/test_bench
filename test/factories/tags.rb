FactoryBot.define do
  # Valid prefixes from the seeds file
  PREFIXES = %w[CC CE CJB CX FT FV HV LT LZ PG PRV PT PZ XV ME MP MV A B LD LE LH LS LW P S SP T US V].freeze
  SUFFIXES = ['', 'A', 'B', 'i', 'z'].freeze
  
  factory :tag do
    sequence(:prefix) { |n| PREFIXES[n % PREFIXES.size] }
    sequence(:serial) { |n| n % 10000 }  # 0-9999
    suffix { SUFFIXES.sample }
    description { "Test #{prefix}-#{'%03d' % serial}#{suffix}" }
    stage { rand(0..3) }  # 0-3 to match seeds.rb phase
    notes { nil }
    
    association :project
    association :discipline
    
    trait :with_suffix do
      sequence(:suffix) { |n| SUFFIXES[n % SUFFIXES.size] }
    end
    
    trait :with_stage do
      stage { rand(1..3) }  # 1-3 to match seeds.rb phase range
    end
    
    trait :with_notes do
      notes { Faker::Lorem.paragraph(sentence_count: 2) }
    end
    
    trait :civil do
      prefix { 'C' }
      description { 'Civil Engineering Tag' }
      association :discipline, :c
    end
    
    trait :electrical do
      prefix { 'EX' }
      description { 'Electrical Tag' }
      association :discipline, :e
    end
    
    trait :mechanical do
      prefix { 'P' }
      description { 'Mechanical Tag' }
      association :discipline, :m
    end
    
    trait :complete do
      with_suffix
      with_stage
      with_notes
    end
    
    trait :sequential do
      sequence(:serial) { |n| n % 10000 }  # Ensure within 0-9999 range
      with_suffix
    end
    
    # Factory for creating tags in sequence (e.g., C-001, C-002, etc.)
    factory :sequential_tag do
      sequence(:serial) { |n| n % 10000 }  # Ensure within 0-9999 range
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
