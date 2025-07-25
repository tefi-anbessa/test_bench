class Tag < ApplicationRecord
  resourcify
  delegated_type :tagable, types: %w[ Cable Load ], optional: true, dependent: :destroy
  accepts_nested_attributes_for :tagable, update_only: true
  belongs_to :project
  belongs_to :discipline

  attribute :full_tag, :string
  after_find :set_full_tag

  validates :prefix, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :prefix, length: { in: 0..6 }
  attr_accessor :new_prefix, :string
  validates :new_prefix, length: { in: 0..6, allow_nil: true }
  before_validation :set_prefix

  validates :serial, presence: true, inclusion: { in: 0..9999 }
  validates :suffix, length: { maximum: 5 }
  validates :description, length: { maximum: 40 }
  validates :phase, inclusion: { in: 0..10 }

  def self.ransackable_attributes(auth_object = nil)
    ["prefix", "serial", "suffix", "description", "full_tag", "project_phase",
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
