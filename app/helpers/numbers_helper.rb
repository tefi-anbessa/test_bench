# frozen_string_literal: true
module NumbersHelper
  include Math
  def normalize(number)
    return false unless number.is_a?(Float)
    e = (log10(number.abs).round(0)/3) * 3
    n = number / 10**e
    [n, e]
  end
end