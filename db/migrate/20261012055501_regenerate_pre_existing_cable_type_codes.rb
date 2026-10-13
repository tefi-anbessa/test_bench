class RegeneratePreExistingCableTypeCodes < ActiveRecord::Migration[8.0]
  # The cable_type split migration (20261012090000) copied the old
  # long-format code into both the new code and spec_summary columns, so
  # every pre-existing row's code was never regenerated to the short
  # primary_role-prefixed form CableType#generate_code now produces for
  # new records - only rows created after that migration got it. Fix the
  # ones left behind (identifiable by still containing '~', which the new
  # format never does), per discipline, in id order.
  def up
    say_with_time "Regenerating short codes for pre-existing cable types" do
      CableType.unscoped.where("code LIKE '%~%'").order(:id).group_by(&:discipline_id).each do |_discipline_id, rows|
        rows.group_by(&:primary_role).each do |primary_role, role_rows|
          prefix = {
            "power_distribution" => "PD",
            "electrical_control" => "CTRL",
            "analog_signal" => "SIG",
            "digital_signal" => "DIG",
            "communication" => "COMM",
            "thermocouple" => "TC",
            "other" => "OTH"
          }.fetch(primary_role, "OTH")

          role_rows.each_with_index do |cable_type, index|
            cable_type.update_column(:code, "#{prefix}-#{(index + 1).to_s.rjust(3, '0')}")
          end
        end
      end
    end
  end

  def down
    # The old long code is still intact in spec_summary - restore it there.
    CableType.unscoped.where.not(spec_summary: nil).find_each do |cable_type|
      cable_type.update_column(:code, cable_type.spec_summary)
    end
  end
end
