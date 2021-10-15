module Concurrent
  # Special "compare and set" handling of numeric values.
  #
  # @!visibility private
  # @!macro internal_implementation_note
  module AtomicNumericCompareAndSetWrapper
    # @!macro atomic_reference_method_compare_and_set
    def compare_and_set(old_value, new_value)
      if old_value.is_a? Numeric
        loop do
          old = get

          return false unless old.is_a? Numeric

          return false unless old == old_value

          result = _compare_and_set(old, new_value)
          return result if result
        end
      else
        _compare_and_set(old_value, new_value)
      end
    end
  end
end
