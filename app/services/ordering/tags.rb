# app/services/ordering/tags.rb
module Ordering
  class Tags < Base
    def clauses
      [
        "disciplines.sort_order ASC",
        "#{sort_key_sql} ASC",
        "tags.full_tag ASC"
      ]
    end

    private

      def sort_key_sql
        <<~SQL.squish
          CASE
            WHEN disciplines.prefix_schema->>'name' = 'isa51'
              OR disciplines.prefix_schema->>'type' = 'isa51'
              THEN tags.loop_id
            ELSE tags.full_tag
          END
        SQL
      end
  end
end
