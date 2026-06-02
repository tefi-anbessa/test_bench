# app/services/ordering/base.rb
module Ordering
  class Base

    def clauses
      raise NotImplementedError
    end
  end
end