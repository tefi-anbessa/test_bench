# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    prefix { 'AA' }  # Default prefix if not provided
    sequence(:serial) { |n| n % 10000 }  # 0-9999
    suffix { '' }    # Default suffix if not provided
    service { "Test #{prefix}-#{'%04d' % serial}#{suffix}" }
    stage { rand(0..3) }  # 0-3 to match seeds.rb phase
    notes { nil }

    # Require project and discipline to be passed in explicitly
    # project - must be provided
    # discipline - must be provided

    trait :with_stage do
      stage { rand(1..3) }  # 1-3 to match seeds.rb phase range
    end

    trait :unique_tag do
      # Override the serial with a database-aware sequence
      serial { generate_unique_serial(prefix, project, discipline) }
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

def generate_unique_serial(prefix, project, discipline)
  # Find the next available serial for this project, discipline, prefix combination
  project_id = project&.id || Project.first&.id
  discipline_id = discipline&.id || Discipline.first&.id

  return 1 unless project_id && discipline_id

  # Find all existing serial numbers for this combination
  existing_serials = Tag.where(
    project_id: project_id,
    discipline_id: discipline_id,
    prefix: prefix
  ).pluck(:serial)

  # Find the next available serial number (fill gaps)
  next_serial = 1
  while existing_serials.include?(next_serial)
    next_serial += 1
  end

  next_serial
end
