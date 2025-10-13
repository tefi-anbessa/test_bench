class AddPolymorphicFromToToCables < ActiveRecord::Migration[8.0]
  def change
    # Add polymorphic "from" association
    add_reference :cables, :from, polymorphic: true, index: true
    
    # Add polymorphic "to" association  
    add_reference :cables, :to, polymorphic: true, index: true
  end
end
