# frozen_string_literal: true
module DocumentControl

  # Source format is a simple collection of software application references, used to avoid duplication. 
  # The collection is not project related, so any entry is available to all.
  # It is linked to document issues, so a document may change its source format through its life cycle.
  # Avoid using the reverse relationship, unless project context is carefully managed.
  class SourceFormat < Base

  # Associatons
  has_many :issues, class_name: "DocumentControl::Issue"
  
  # Presence validation for required fields.
  validates :title, presence: true, length: { maximum: 50 }
  
  # Uniqueness validation for unique fields.
  validates :revision, uniqueness: { scope: :title }, length: { maximum: 20 }

  validates :file_extension, length: { maximum: 10 }, format: { with: /\A\./ }
    
  def label
    "#{title} #{revision}"
  end

  private

    def self.ransackable_attributes(auth_object = nil)
      [:vendor, :title, :file_extension, :revision, :notes, :created_at, :updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :issues ]
    end
  end
end
