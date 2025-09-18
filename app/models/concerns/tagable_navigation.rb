module TagableNavigation
  extend ActiveSupport::Concern
  
  included do
    # Ensure we have a tag
    before_validation :ensure_tag_exists
  end
  
  # Get the next record in the project, ordered by discipline, loop_id, prefix, and suffix
  # @param attribute [Symbol] The attribute to order by (default: :loop_id)
  # @return [self] Returns the next record or self if there isn't one
  def next(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag(:next) || self
  end

  # Get the previous record in the project, ordered by discipline, loop_id, prefix, and suffix
  # @param attribute [Symbol] The attribute to order by (default: :loop_id)
  # @return [self] Returns the previous record or self if there isn't one
  def prev(attribute = :loop_id)
    return super(attribute) unless attribute == :loop_id
    
    adjacent_tag(:prev) || self
  end
  
  private
  
  # Find adjacent record based on the given direction
  # @param direction [Symbol] Either :prev for previous or :next for next record
  def adjacent_tag(direction)
    return unless tag.present?
    
    column = "#{direction}_id"
    model_class = self.class
    
    sql = <<-SQL
      WITH ordered_tags AS (
        SELECT id,
               discipline_id,
               loop_id,
               prefix,
               COALESCE(suffix, '') as suffix_sort,
               tagable_type,
               LAG(id) OVER (
                 PARTITION BY tagable_type 
                 ORDER BY discipline_id, loop_id, prefix, COALESCE(suffix, '')
               ) as prev_id,
               LEAD(id) OVER (
                 PARTITION BY tagable_type 
                 ORDER BY discipline_id, loop_id, prefix, COALESCE(suffix, '')
               ) as next_id
        FROM tags
        WHERE project_id = :project_id
          AND tagable_type = :model_name
      )
      SELECT #{model_class.table_name}.*
      FROM #{model_class.table_name}
      JOIN tags ON #{model_class.table_name}.id = tags.tagable_id AND tags.tagable_type = :model_name
      JOIN ordered_tags ot ON tags.id = ot.#{column}
      WHERE ot.id = :current_tag_id
    SQL
    
    model_class.find_by_sql([
      sql, 
      { 
        project_id: tag.project_id, 
        current_tag_id: tag.id,
        model_name: model_class.name
      }
    ]).first
  end
  
  # Ensure the record has a tag
  def ensure_tag_exists
    return if tag.present?
    errors.add(:base, 'must have a tag')
    throw :abort
  end
end
