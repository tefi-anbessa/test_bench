class AddLoadableToLoads < ActiveRecord::Migration[7.0]
  def change
    add_reference :loads, :loadable, polymorphic: true
  end
end
