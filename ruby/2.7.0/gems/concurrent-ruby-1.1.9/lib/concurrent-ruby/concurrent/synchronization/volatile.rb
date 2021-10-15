module Concurrent
  module Synchronization
    # Volatile adds the attr_volatile class method when included.
    #
    # @example
    #   class Foo
    #     include Concurrent::Synchronization::Volatile
    #
    #     attr_volatile :bar
    #
    #     def initialize
    #       self.bar = 1
    #     end
    #   end
    #
    #  foo = Foo.new
    #  foo.bar
    #  => 1
    #  foo.bar = 2
    #  => 2

    Volatile = if Concurrent.on_cruby?
                 MriAttrVolatile
               elsif Concurrent.on_jruby?
                 JRubyAttrVolatile
               elsif Concurrent.on_rbx?
                 RbxAttrVolatile
               elsif Concurrent.on_truffleruby?
                 TruffleRubyAttrVolatile
               else
                 MriAttrVolatile
               end
  end
end
