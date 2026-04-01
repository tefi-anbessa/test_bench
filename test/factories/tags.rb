# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    prefix { 'AA' }  # Default prefix if not provided
    sequence(:serial) { |n| n % 10000 }  # 0-9999
    suffix { '' }    # Default suffix if not provided
    service { "Test #{prefix}-#{'%04d' % serial}#{suffix}" }
    stage { 0 }  # Default stage to 0
    notes { Faker::Lorem.paragraph(sentence_count: 2) }
    association :discipline

    # Allow passing project through to discipline
    transient do
      project { nil }
    end

    # Initialize discipline with project if provided
    after(:build) do |tag, evaluator|
      if evaluator.project && !evaluator.discipline
        tag.discipline = build(:discipline, project: evaluator.project)
      end
    end

    trait :unique_tag do
      # Override the serial with a database-aware sequence
      after(:build) do |tag, _evaluator|
        # Ensure discipline is set before generating serial
        if tag.discipline
          tag.serial = generate_unique_serial(tag.prefix, tag.discipline)
        else
          # Fallback to simple serial if no discipline
          tag.serial = 1
        end
      end
    end
  end
end

def generate_unique_serial(prefix, discipline)
  return 1 unless discipline

  # Find all existing serial numbers for this combination
  existing_serials = Tag.where(
    discipline_id: discipline.id,
    prefix: prefix
  ).pluck(:serial)

  # Find the next available serial number (fill gaps)
  next_serial = 1
  while existing_serials.include?(next_serial)
    next_serial += 1
  end

  next_serial
end
