class Tag < ApplicationRecord
  belongs_to :project
  belongs_to :discipline

  attribute :full_tag, :string
  after_find :set_full_tag

  validates :prefix, presence: true, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :prefix, length: { in: 1..6 }
  validates :serial, presence: true, inclusion: { in: 0..9999 }
  validates :suffix, length: { maximum: 5 }
  validates :description, length: { maximum: 40 }
  validates :phase, inclusion: { in: 0..10 }

  def self.ransackable_attributes(auth_object = nil)
    ["prefix", "serial", "suffix", "full_tag", "description", "phase", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["discipline", "project"]
  end

  private

    def set_full_tag
    # Set the full_tag on the instance using self.full_tag
    self.full_tag = "#{prefix}-#{self.serial.to_s.rjust(4, '0')}"

    # Add suffix if it's present
    self.full_tag += ".#{suffix}" if suffix.present?
    end
end
