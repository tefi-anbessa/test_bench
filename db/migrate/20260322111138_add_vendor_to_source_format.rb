class AddVendorToSourceFormat < ActiveRecord::Migration[8.0]
  def change
    add_column :document_control_source_formats, :vendor, :string
  end
end
