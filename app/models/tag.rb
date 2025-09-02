class Tag < ApplicationRecord
  resourcify
  delegated_type :tagable, types: Constants.tagable, optional: true, dependent: :destroy
  accepts_nested_attributes_for :tagable, update_only: true
  belongs_to :project
  belongs_to :discipline

  attribute :full_tag, :string
  after_find :set_full_tag

  validates :prefix, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :prefix, length: { in: 1..6 }
  attr_accessor :new_prefix, :string
  validates :new_prefix, length: { in: 1..6, allow_nil: true }
  before_validation :set_prefix

  validates :serial, presence: true, inclusion: { in: 0..9999 }
  validates :suffix, length: { maximum: 5 }
  validates :description, length: { maximum: 40 }
  validates :stage, inclusion: { in: 0..10 }
  validate :validate_tagable_assignment, on: :update
  validate :validate_tagable_existence

  # Allow setting tagable_type without tagable_id to indicate intended type
  # Only validate presence of tagable_id if we're setting a non-nil value
  validates :tagable_id, presence: { message: 'must be present when setting a tagable' }, 
                         if: -> { tagable_type.present? && tagable_id_changed? && tagable_id.present? }
  validates :tagable_type, inclusion: { in: Constants.tagable.map(&:to_s) }, 
                           allow_nil: true,
                           allow_blank: true
  
  # Ensure a tagable is only associated with one tag
  validate :tagable_not_already_taken, if: -> { tagable_id.present? && tagable_type.present? }

  # Track original values to detect changes
  def initialize(*)
    super
    @original_tagable_type = tagable_type
    @original_tagable_id = tagable_id
  end

  private
  
  def tagable_not_already_taken
    return unless tagable_id.present? && tagable_type.present?
    
    existing_tag = Tag.where(
      tagable_id: tagable_id,
      tagable_type: tagable_type
    ).where.not(id: id).exists?
    
    if existing_tag
      errors.add(:tagable, 'is already associated with another tag')
    end
  end

  # Prevent changing tagable association if it's already set and valid
  def validate_tagable_assignment
    return unless tagable_type_changed? || tagable_id_changed?
    return if tagable_id_was.blank? || tagable_type_was.blank?
    
    # Allow changes if the current association is invalid
    return if tagable_type_was.constantize.where(id: tagable_id_was).none?
    
    errors.add(:base, 'Cannot change tagable association once set') 
  end

  # Ensure tagable exists if both type and id are present
  def validate_tagable_existence
    return if tagable_id.blank? || tagable_type.blank?
    
    begin
      tagable_class = tagable_type.constantize
      return if tagable_class.exists?(tagable_id)
      
      errors.add(:tagable, 'must exist')
    rescue NameError
      errors.add(:tagable_type, 'is not a valid type')
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["prefix", "serial", "suffix", "description", "full_tag", "stage",
      "notes", "discipline_id", "created_at", "updated_at"]
  end


  def self.ransackable_associations(auth_object = nil)
    ["discipline", "project"]
  end

  private

    def set_full_tag
      # Set the full_tag on the instance using self.full_tag
      discipline = Discipline.find(self.discipline_id).code
      self.full_tag = "#{discipline}:#{prefix}-#{self.serial.to_s.rjust(4, '0')}"

      # Add suffix if it's present
      self.full_tag += ".#{suffix}" if suffix.present?
    end

    def set_prefix
      if self.new_prefix.present? && self.prefix.empty?
        self.prefix = self.new_prefix
      end
    end
end
