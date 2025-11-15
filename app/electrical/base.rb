module Electrical
  class Base < ApplicationRecord
    self.abstract_class = true
    # Add shared module behavior here
  end
end