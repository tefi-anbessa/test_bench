FactoryBot.define do
  factory :tag do
    prefix { 'AA' }  # Default prefix if not provided
    sequence(:serial) { |n| n % 10000 }  # 0-9999
    suffix { '' }    # Default suffix if not provided
    service { "Test #{prefix}-#{'%03d' % serial}#{suffix}" }
    stage { rand(0..3) }  # 0-3 to match seeds.rb phase
    notes { nil }

    # Require project and discipline to be passed in explicitly
    # project - must be provided
    # discipline - must be provided

    trait :with_stage do
      stage { rand(1..3) }  # 1-3 to match seeds.rb phase range
    end

    trait :unique_tag do
      # Remove fixed prefix to allow customization
      sequence(:serial) do |n|
        # Find the next available serial for this project, discipline, prefix, and suffix combination
        last_tag = Tag.where(
          project: project || Project.first,
          discipline: discipline || Discipline.first,
          prefix: prefix
        ).order(serial: :desc).first

        last_tag ? last_tag.serial + 1 : n
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
      notes { Faker::Lorem.paragraph(sentence_count: 2) }
    end
  end
end
