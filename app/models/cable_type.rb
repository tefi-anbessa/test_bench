# frozen_string_literal: true

# Shared, core model - every discipline's cable types are CableType rows,
# distinguished only by discipline and by which concrete detail subtype
# backs them (see delegated_type below). Not every discipline needs
# genuinely different attributes for the bulk of a cable type's spec
# (construction, conductor material, insulation, ...) - only the small
# remainder that's truly discipline-specific (e.g. a power cable's
# neutral/earth conductors, an instrument cable's screening) lives on the
# delegated detail class. Mirrors Tag's own delegated_type :tagable in
# shape - the detail classes are to CableType what tagable models are to
# Tag.
class CableType < ApplicationRecord
  # === Mixins ===

  # === Constants ===
  # Index can be reached scoped to either parent - discipline is this
  # record's own true, direct parent (see belongs_to below); project is a
  # broader, index-only convenience. Order matters - the first entry is
  # the primary scope used for show/edit/update/destroy, which have no
  # parent param of their own to resolve from (see NestedResourcesController#nesting).
  NESTED_SCOPES = %i[discipline project].freeze

  # prefix: true avoids an enum method clash - both primary_role and
  # voltage_rating have an "other" option, which would otherwise both try
  # to define the same bare #other? method.
  enum :primary_role, Constants.cable.primary_roles.to_h, prefix: true
  enum :construction, Constants.cable.constructions.to_h
  enum :conductor_material, Constants.cable.conductor_materials.to_h
  insulation_materials = Constants.cable.insulation_materials.to_h
  enum :insulation, insulation_materials, prefix: true
  enum :bedding, insulation_materials, prefix: true
  enum :armour, Constants.cable.armour_materials.to_h, prefix: true
  enum :sheath, insulation_materials, prefix: true
  enum :voltage_rating, Constants.cable.voltage_ratings.to_h
  enum :temperature_rating, Constants.cable.temperature_rating.each_with_index.to_h
  enum :fire_protection, Constants.cable.fire_protection.to_h

  # === Gem macros ===
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  belongs_to :discipline, required: true
  has_one :project, through: :discipline
  has_many :cables, dependent: :destroy

  delegated_type :detail, types: %w[Electrical::CableTypeDetail Instrument::CableTypeDetail], dependent: :destroy
  accepts_nested_attributes_for :detail

  # === Scopes ===

  # === Validations ===
  validates :conductor_material, :groups, :construction, :csa, :primary_role, :detail, presence: true
  validate :detail_matches_discipline_module

  # === Callbacks ===
  before_save :generate_code

  # === Class methods ===

  # === Class methods - Queries ===
  def self.navigator_order_sql
    "cable_types.code ASC"
  end

  # === Public methods ===
  def label
    code
  end

  def long_label
    "#{discipline.long_label} - #{code}"
  end

  def generate_code
    sequence_number = find_next_sequence_number
    new_code = "#{primary_role_prefix}-#{sequence_number.to_s.rjust(3, '0')}"
    self.code = new_code if new_record? || will_save_change_to_primary_role?
    self.spec_summary = generate_spec_summary
  end

  # === Private methods ===
  private

    def primary_role_prefix
      {
        "power_distribution" => "PD",
        "electrical_control" => "CTRL",
        "analog_signal" => "SIG",
        "digital_signal" => "DIG",
        "communication" => "COMM",
        "thermocouple" => "TC",
        "other" => "OTH"
      }.fetch(primary_role, "OTH")
    end

    def detail_matches_discipline_module
      return if detail.blank? || discipline.blank?
      expected_class = discipline.cable_type_detail_class
      return if expected_class.nil? || detail.is_a?(expected_class)
      errors.add(:detail, I18n.t("activerecord.errors.models.cable_type.attributes.detail.discipline_mismatch"))
    end

    def find_next_sequence_number
      existing_codes = CableType
        .where(discipline_id: discipline_id)
        .where("code LIKE ?", "#{primary_role_prefix}-%")
        .where.not(id: id)
        .pluck(:code)

      sequence_numbers = existing_codes.filter_map do |code|
        match = code.match(/-(\d+)\z/)
        match && match[1].to_i
      end

      sequence_numbers.any? ? sequence_numbers.max + 1 : 1
    end

    def construction_code
      case construction
      when 'core' then 'C'
      when 'pair' then 'pr'
      when 'triple' then 'tr'
      else 'C'
      end
    end

    # A readable full-spec summary, for a quick glance at a cable type's
    # construction - not an identifier, see #code for that.
    def generate_spec_summary
      parts = []
      parts << conductor_material
      parts << "#{csa}mm²"
      parts << "#{groups}#{construction_code}"
      parts << insulation if insulation.present?
      parts << bedding if bedding.present?
      parts << armour if armour.present?
      parts << sheath if sheath.present?
      parts << voltage_rating if voltage_rating.present?
      parts << temperature_rating if temperature_rating.present?
      parts.join('~')
    end

    def self.ransackable_attributes(auth_object = nil)
      ["label", "conductor_material", "csa", "groups", "construction",
        "insulation", "bedding", "armour", "sheath", "bedding_od", "overall_od",
        "temperature_rating", "voltage_rating", "primary_role", "fire_protection", "code",
        "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["cables", "detail"]
    end
end
