module Capybara
  module Driver
    class Node
      attr_reader :driver, :native, :initial_cache

      def initialize(driver, native, initial_cache = {})
        @driver = driver
        @native = native
        @initial_cache = initial_cache
      end

      def all_text
        raise NotImplementedError
      end

      def visible_text
        raise NotImplementedError
      end

      def [](_name)
        raise NotImplementedError
      end

      def value
        raise NotImplementedError
      end

      def style(_styles)
        raise NotImplementedError
      end

      # @param value [String, Array] Array is only allowed if node has 'multiple' attribute
      # @param options [Hash] Driver specific options for how to set a value on a node
      def set(_value, **_options)
        raise NotImplementedError
      end

      def select_option
        raise NotImplementedError
      end

      def unselect_option
        raise NotImplementedError
      end

      def click(_keys = [], **_options)
        raise NotImplementedError
      end

      def right_click(_keys = [], **_options)
        raise NotImplementedError
      end

      def double_click(_keys = [], **_options)
        raise NotImplementedError
      end

      def send_keys(*_args)
        raise NotImplementedError
      end

      def hover
        raise NotImplementedError
      end

      def drag_to(_element, **_options)
        raise NotImplementedError
      end

      def drop(*_args)
        raise NotImplementedError
      end

      def scroll_by(_x, _y)
        raise NotImplementedError
      end

      def scroll_to(_element, _alignment, _position = nil)
        raise NotImplementedError
      end

      def tag_name
        raise NotImplementedError
      end

      def visible?
        raise NotImplementedError
      end

      def obscured?
        raise NotImplementedError
      end

      def checked?
        raise NotImplementedError
      end

      def selected?
        raise NotImplementedError
      end

      def disabled?
        raise NotImplementedError
      end

      def readonly?
        !!self[:readonly]
      end

      def multiple?
        !!self[:multiple]
      end

      def rect
        raise NotSupportedByDriverError, 'Capybara::Driver::Node#rect'
      end

      def path
        raise NotSupportedByDriverError, 'Capybara::Driver::Node#path'
      end

      def trigger(_event)
        raise NotSupportedByDriverError, 'Capybara::Driver::Node#trigger'
      end

      def inspect
        %(#<#{self.class} tag="#{tag_name}" path="#{path}">)
      rescue NotSupportedByDriverError
        %(#<#{self.class} tag="#{tag_name}">)
      end

      def ==(_other)
        raise NotSupportedByDriverError, 'Capybara::Driver::Node#=='
      end
    end
  end
end
