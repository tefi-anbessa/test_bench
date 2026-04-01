FactoryBot.define do
  factory :electrical_socket_cct, class: 'Electrical::SocketCct' do
    # Tag can be passed explicitly, otherwise will be auto-created
    transient do
      tag { nil }
    end
    # Attributes
    socket_type { "10A" }
    quantity { 1 }

    # Create tag association in a single transaction
    before(:create) do |socket_cct, evaluator|
      if evaluator.tag
        # Use provided tag, but ensure it's not already associated
        if evaluator.tag.tagable.present?
          raise "Tag is already associated with another record: #{evaluator.tag.tagable_type}##{evaluator.tag.tagable_id}"
        end
        socket_cct.tag = evaluator.tag
      else
        # Create new tag with proper discipline in same transaction
        discipline = Discipline.find_by(name: socket_cct.class.discipline) || 
             create(:discipline, name: socket_cct.class.discipline)
        socket_cct.tag = create(:tag, :unique_tag, discipline: discipline)
      end
    end
  end
end
