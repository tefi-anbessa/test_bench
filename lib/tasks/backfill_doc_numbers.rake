namespace :documents do
  desc "Backfill missing doc_numbers for existing documents"
  task backfill_doc_numbers: :environment do
    puts "Backfilling doc_numbers for existing documents..."
    
    documents_without_doc_number = Document.where(doc_number: [nil, ''])
    
    if documents_without_doc_number.empty?
      puts "No documents found without doc_numbers."
      exit
    end
    
    puts "Found #{documents_without_doc_number.count} documents without doc_numbers"
    
    documents_without_doc_number.find_each do |document|
      next unless document.discipline.present? && document.doc_type.present?
      
      # Set serial
      max_serial = Document.where(discipline_id: document.discipline_id, doc_type_id: document.doc_type_id).where.not(id: document.id).maximum(:serial) || 0
      document.serial = max_serial.to_i + 1
      
      # Set doc_number
      separator = Constants.document_control.separator
      document.doc_number = "#{document.discipline.project.label}#{separator}#{document.discipline.label}#{separator}#{document.doc_type.code}#{separator}#{document.serial.to_s.rjust(Constants.document_control.serial_digits, '0')}"
      
      if document.save(validate: false) # Skip validations since we're fixing data
        puts "Updated document ##{document.id}: #{document.doc_number}"
      else
        puts "Failed to update document ##{document.id}: #{document.errors.full_messages.join(', ')}"
      end
    end
    
    puts "Backfill completed!"
  end
end
