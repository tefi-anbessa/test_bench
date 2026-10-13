# frozen_string_literal: true

FactoryBot.define do
  factory :cable do
    transient do
      tag { nil }
      discipline { nil }
      cable_type { nil }
      from { nil }  # Source object (Circuit, Switchboard, etc.)
      to { nil }    # Destination object (Demand, Motor, etc.)
      cable_type_attributes { {} }
    end

    # Optional attributes
    route_length { 10 }  # meters
    vertical_allowance { 6 }  # meters
    termination_allowance { 4 }  # meters per end
    start_mark { 1001 }
    end_mark { 1010 }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    # Handle associations for both build and create
    after(:build) do |cable, evaluator|
      # Set from/to associations
      cable.from = evaluator.from if evaluator.from
      cable.to = evaluator.to if evaluator.to

      # Resolve the discipline FIRST, in priority order - everything else
      # built below (an auto-built cable_type, an auto-built tag) must
      # agree with it, since a cable's discipline (via its tag) must
      # always match its cable_type's discipline. A given tag is the
      # strongest signal (the tag already has a real, fixed discipline);
      # only fall back to the cable_type's own discipline when nothing
      # else pins it down.
      resolved_discipline =
        if evaluator.tag
          tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
          tag.discipline
        elsif evaluator.discipline
          evaluator.discipline
        elsif evaluator.cable_type
          evaluator.cable_type.discipline
        end

      # Create cable_type if not provided (polymorphic - assigning a real
      # record sets both cable_type_id and cable_type_type), built under
      # the resolved discipline so it can't disagree with it.
      unless cable.cable_type
        attrs = evaluator.cable_type_attributes.dup
        attrs[:discipline] = resolved_discipline if resolved_discipline
        cable.cable_type = evaluator.cable_type || build(:electrical_cable_type, attrs)
      end

      resolved_discipline ||= cable.cable_type.discipline

      # Create tag if not provided
      unless cable.tag
        if evaluator.tag
          tag = evaluator.tag.is_a?(Tag) ? evaluator.tag : Tag.find(evaluator.tag)
          if tag.tagable.present?
            raise "Tag is already associated with another record: #{tag.tagable_type}##{tag.tagable_id}"
          end
          cable.tag = tag
        else
          cable.tag = create(:tag, :unique_tag, discipline: resolved_discipline)
        end
      end

      # Set directly (not just relying on has_one :discipline, through: :tag,
      # which can't resolve reliably before this record is persisted - see
      # Cable#creation_discipline for why).
      cable.creation_discipline = resolved_discipline
    end
  end
end
