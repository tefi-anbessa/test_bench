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
