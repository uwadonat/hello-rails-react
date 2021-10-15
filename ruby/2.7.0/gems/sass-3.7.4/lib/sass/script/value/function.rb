module Sass::Script::Value
  # A SassScript object representing a function.
  class Function < Callable
    # Constructs a Function value for use in SassScript.
    #
    # @param function [Sass::Callable] The callable to be used when the
    # function is invoked.
    def initialize(function)
      raise ArgumentError, 'A callable of type function was expected.' unless function.type == 'function'
      super
    end

    def to_sass
      %{get-function("#{value.name}")}
    end
  end
end
