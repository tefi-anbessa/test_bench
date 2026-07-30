# frozen_string_literal: true

module NumbersHelper
  include Math
  include ActiveSupport::NumberHelper
  SI_PREFIX ||= { -18 => "a", -15 => "f", -12 => "p", -9 => "n", -6 => "μ", -3 => "m", 0 => "", 3 => "k", 6 => "M", 9 => "G", 12 => "T", 15 => "P", 18 => "E" }.freeze
  def normalize(number)
    if number > Float::MIN
      e = (log10(number.abs).round(0)/3) * 3
      n = number / 10**e
      [n, e]
    else
      [0.0, 0]
    end
  end

  def format_number(number, precision: 4, significant: true, units: "")
    if number.is_a?(Numeric)
      n, e = normalize(number)
      if e.in?(SI_PREFIX.keys)
        units = SI_PREFIX[e] + units
        [number_to_rounded(n, precision: precision, significant: significant), units].join(" ")
      else
        [[number_to_rounded(n, precision: precision, significant: significant), e].join('E'), units].join(" ")
      end
    else
      I18n.t("show.not_numeric")
    end
  end
end