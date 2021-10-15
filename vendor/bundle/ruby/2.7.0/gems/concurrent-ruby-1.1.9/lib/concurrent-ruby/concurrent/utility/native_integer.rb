module Concurrent
  module Utility
    # @private
    module NativeInteger
      # http://stackoverflow.com/questions/535721/ruby-max-integer
      MIN_VALUE = -(2**(0.size * 8 - 2))
      MAX_VALUE = (2**(0.size * 8 - 2) - 1)

      def ensure_upper_bound(value)
        raise RangeError, "#{value} is greater than the maximum value of #{MAX_VALUE}" if value > MAX_VALUE
        value
      end

      def ensure_lower_bound(value)
        raise RangeError, "#{value} is less than the maximum value of #{MIN_VALUE}" if value < MIN_VALUE
        value
      end

      def ensure_integer(value)
        raise ArgumentError, "#{value} is not an Integer" unless value.is_a?(Integer)
        value
      end

      def ensure_integer_and_bounds(value)
        ensure_integer value
        ensure_upper_bound value
        ensure_lower_bound value
      end

      def ensure_positive(value)
        raise ArgumentError, "#{value} cannot be negative" if value < 0
        value
      end

      def ensure_positive_and_no_zero(value)
        raise ArgumentError, "#{value} cannot be negative or zero" if value < 1
        value
      end

      extend self
    end
  end
end
