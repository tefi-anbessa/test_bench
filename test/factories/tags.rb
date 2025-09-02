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
    
    # Use default project factory
    project

    # Use find_or_create_by to avoid unique constraint violations
    discipline { Discipline.find_or_create_by(code: 'E', name: 'Electrical Engineering') }
    
    trait :with_stage do
      stage { rand(1..3) }  # 1-3 to match seeds.rb phase range
    end
    
    trait :with_notes do
      notes { Faker::Lorem.paragraph(sentence_count: 2) }
    end

    trait :unique_tag do
      prefix { 'CC' } # default the prefix in cases where it is not specified
      serial do
        cc = Tag.where(prefix: prefix).order(serial: :asc).last
        cc ? cc.serial + 1 : 1
      end
    end
    
    trait :sequential do
      sequence(:serial) { |n| n % 10000 }  # Ensure within 0-9999 range
    end
    
    # Factory for creating tags in sequence (e.g., C-001, C-002, etc.)
    factory :sequential_tag do
      sequence(:serial) { |n| n % 10000 }  # Ensure within 0-9999 range
    end
    
    # Factory for creating a full tag with all attributes
    factory :complete_tag do
      with_stage
      with_notes
    end
  end
end
