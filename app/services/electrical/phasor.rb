module Electrical
  # A current phasor: magnitude (A) at some phase angle (power factor).
  # Wraps Complex so that summing several loads on the same line is a plain +.
  class Phasor
    def self.from_current(current, power_factor)
      angle = Math.acos(power_factor.to_f.clamp(-1.0, 1.0))
      new(Complex(current.to_f * Math.cos(angle), current.to_f * Math.sin(angle)))
    end

    def self.zero
      new(Complex(0, 0))
    end

    def initialize(complex)
      @complex = complex
    end

    def +(other)
      self.class.new(@complex + other.to_c)
    end

    def *(scalar)
      self.class.new(@complex * scalar)
    end

    def current
      @complex.abs
    end

    def power_factor
      return 1.0 if current.zero?
      Math.cos(@complex.arg)
    end

    def to_c
      @complex
    end
  end
end
