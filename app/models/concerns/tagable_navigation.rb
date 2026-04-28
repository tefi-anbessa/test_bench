module TagableNavigation
  extend ActiveSupport::Concern
  
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
        SELECT t.id,
              t.tagable_id,
              t.tagable_type,
              LAG(t.id) OVER (
                PARTITION BY t.tagable_type 
                ORDER BY d.project_id, t.discipline_id, t.loop_id, t.prefix, COALESCE(t.suffix, '')
              ) as prev_id,
              LEAD(t.id) OVER (
                PARTITION BY t.tagable_type 
                ORDER BY d.project_id, t.discipline_id, t.loop_id, t.prefix, COALESCE(t.suffix, '')
              ) as next_id
        FROM tags t
        INNER JOIN disciplines d ON t.discipline_id = d.id
        WHERE d.project_id = :project_id
          AND t.tagable_type = :model_name
      )
      SELECT #{column} FROM ordered_tags
      WHERE id = :current_tag_id
    SQL
    
    adjacent_tag_id = model_class.connection.select_value(
      model_class.send(:sanitize_sql_array, [
        sql, 
        { 
          project_id: tag.discipline.project_id, 
          current_tag_id: tag.id,
          model_name: model_class.name
        }
      ])
    )
    
    return unless adjacent_tag_id
    
    # Find the actual tagable record using the adjacent tag
    adjacent_tag = Tag.find_by(id: adjacent_tag_id)
    adjacent_tag&.tagable
  end
end
