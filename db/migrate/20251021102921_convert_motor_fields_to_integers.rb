class ConvertMotorFieldsToIntegers < ActiveRecord::Migration[8.0]
  def change
    change_column :motors, :motor_type, :integer
    change_column :motors, :frame_size, :integer
  end
end
