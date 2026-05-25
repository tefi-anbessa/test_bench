# frozen_string_literal: true

require "test_helper"
require "helpers/discipline_model_tests"
class DocumentTest < ActiveSupport::TestCase
  include DisciplineModelTests

  def setup
    @project = create(:project)
    @discipline = @project.disciplines.find_by(name: 'Electrical')
    @dt = create(:doc_type, discipline: @discipline, code: "DOC", name: "Test Document Type")
    @resource = create(:document, discipline: @discipline, doc_type: @dt)
  end

  test "title must be present" do
    @resource.title = nil
    refute @resource.valid?
    assert_includes @resource.errors[:title], I18n.t("errors.messages.blank")
  end

  test "title must not be too long" do
    @resource.title = "a" * 51
    refute @resource.valid?
    assert_includes @resource.errors[:title], I18n.t("errors.messages.too_long", count: 50)
  end

  test "document number is correctly generated" do
    # Find the expected serial number of the new document.
    # This test could fail due to race condition with parallel tests...
    serial = Document.where(discipline: @discipline, doc_type: @dt).maximum(:serial) || 0 
    serial += 1
    # Create a document and verify the doc_number format
    doc = create(:document, discipline: @discipline, doc_type: @dt)
    
    # Use the same logic as the model to generate expected format
    separator = Constants.documents.separator
    digits = Constants.documents.serial_digits
    expected_format = "#{@discipline.project.label}#{separator}#{@discipline.code}#{separator}#{@dt.code}#{separator}#{serial.to_s.rjust(digits, '0')}"
    
    assert_equal expected_format, doc.doc_number
    assert_equal serial, doc.serial
  end

  test "default scope sorts by discipline.code, doc type code, then serial" do
    # Create documents with different disciplines and doc types
    discipline_e = @project.disciplines.find_by(code: "E")
    discipline_j = @project.disciplines.find_by(code: "J")
    
    doc_type_a = create(:doc_type, code: "AAA", discipline: discipline_e)
    doc_type_b = create(:doc_type, code: "BBB", discipline: discipline_j)
    
    # Create documents in a specific order to test sorting
    doc1 = create(:document, discipline: discipline_j, doc_type: doc_type_b, title: "Doc 1")
    doc2 = create(:document, discipline: discipline_e, doc_type: doc_type_a, title: "Doc 2")
    doc3 = create(:document, discipline: discipline_e, doc_type: doc_type_a, title: "Doc 3")
    
    # Get all documents and verify order
    documents = Document.all
    
    # Find the documents we created for this test
    test_docs = documents.select { |doc| [doc1.id, doc2.id, doc3.id].include?(doc.id) }
    
    # Should be ordered by discipline.code (A before B), then doc type code, then serial
    # Filter to only our test documents to avoid interference from setup data
    ordered_test_docs = test_docs.sort_by { |doc| [doc.discipline.code, doc.doc_type.code, doc.serial] }
    
    # Verify the actual order matches the expected order
    assert_equal ordered_test_docs, test_docs
    
    # Specifically verify E discipline docs come before J discipline docs
    e_docs = test_docs.select { |doc| doc.discipline.code == "E" }
    # j_docs = test_docs.select { |doc| doc.discipline.code == "J" }
    
    # Within E discipline, verify serial ordering
    assert e_docs.first.serial < e_docs.last.serial
  end

  test "readonly attributes cannot be changed" do
    # Test discipline_id cannot be changed
    new_discipline = @project.disciplines.find_by(name: 'Mechanical')
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @resource.update(discipline: new_discipline)
    end
    
    # Test doc_type_id cannot be changed
    new_doc_type = create(:doc_type, discipline: @discipline)
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @resource.update(doc_type: new_doc_type)
    end
    
    # Test serial cannot be changed
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @resource.update(serial: 999)
    end
  end

end
