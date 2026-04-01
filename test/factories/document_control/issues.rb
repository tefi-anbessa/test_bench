FactoryBot.define do
  factory :document_control_issue, class: DocumentControl::Issue do
    # Attributes
    association :document
    code { generate_next_code_for_document(document) }
    reason { "Issued for Design" }
    # Handle source_format - use provided one or leave nil
    after(:build) do |issue, evaluator|
      if evaluator.source_format
        issue.source_format = evaluator.source_format
      end
      # Don't create anything if not provided - leave as nil
    end
  end
end

def generate_next_code_for_document(document)
  return "A" unless document

  # Find all existing codes for this document
  existing_codes = DocumentControl::Issue.where(document_id: document.id)
                                        .pluck(:code)
                                        .sort

  # Find the next available code
  last_code = existing_codes.last
  last_code ? last_code.succ : "A"
end
