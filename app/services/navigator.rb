# app/services/navigator.rb
class Navigator
  def initialize(scope:, record:)
    @scope  = scope
    @record = record
  end

  def prev
    neighbours[0]
  end

  def next
    neighbours[1]
  end

  def neighbours
    ranked = ranked_cte

    rows = @scope.klass
      .with(ranked: ranked)
      .from("ranked")
      .select("ranked.*")
      .where(<<~SQL, id: @record.id)
        row_number BETWEEN (
          SELECT row_number - 1 FROM ranked WHERE id = :id
        ) AND (
          SELECT row_number + 1 FROM ranked WHERE id = :id
        )
      SQL
      .order("row_number")
      .to_a

    split_neighbours(rows)
  end

  private

    def ranked_cte
      @scope
        .left_joins(:discipline)
        .select(<<~SQL)
          #{@scope.table_name}.*,
          ROW_NUMBER() OVER (ORDER BY #{order_sql}) AS row_number
        SQL
    end
    
    def split_neighbours(rows)
      return [nil, nil] if rows.empty?

      current = rows.find { |r| r.id == @record.id }
      return [nil, nil] unless current

      prev = rows.find { |r| r.row_number == current.row_number - 1 }
      nxt  = rows.find { |r| r.row_number == current.row_number + 1 }

      [prev, nxt]
    end

    def order_sql
      @record.class.navigator_order_sql
    end
end