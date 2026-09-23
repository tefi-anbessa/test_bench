module Tagable
  extend ActiveSupport::Concern

  included do
    has_one :tag, as: :tagable, dependent: :nullify
    has_one :discipline, through: :tag
    has_one :project, through: :discipline
    accepts_nested_attributes_for :tag
    delegate :full_tag, :stage, :label, :long_label, :service, :location, to: :tag, allow_nil: true  
    
    # === Gem macros ===
    has_paper_trail

    # === Class methods - Queries ===
    # Provide SQL for ordering tags in the navigator
    # Tag model is a special case, tags are ordered differently if the discipline uses ISA51 type prefix schema
    def self.navigator_order_sql
      <<~SQL.squish
        projects.code ASC,
        disciplines.sort_order ASC,
        CASE
          WHEN COALESCE(
            disciplines.prefix_schema->>'type',
            disciplines.prefix_schema->>'name'
          ) = 'isa51'
          THEN tags.loop_id
          ELSE tags.full_tag
        END ASC,
        tags.full_tag ASC
      SQL
    end
  end
end
