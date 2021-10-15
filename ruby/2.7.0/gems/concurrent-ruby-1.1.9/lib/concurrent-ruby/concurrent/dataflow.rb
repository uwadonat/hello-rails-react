require 'concurrent/future'
require 'concurrent/atomic/atomic_fixnum'

module Concurrent
  # @!visibility private
  class DependencyCounter # :nodoc:
    def initialize(count, &block)
      @counter = AtomicFixnum.new(count)
      @block = block
    end

    def update(_time, _value, _reason)
      @block.call if @counter.decrement == 0
    end
  end

  # Dataflow allows you to create a task that will be scheduled when all of its data dependencies are available.
  # {include:file:docs-source/dataflow.md}
  #
  # @param [Future] inputs zero or more `Future` operations that this dataflow depends upon
  #
  # @yield The operation to perform once all the dependencies are met
  # @yieldparam [Future] inputs each of the `Future` inputs to the dataflow
  # @yieldreturn [Object] the result of the block operation
  #
  # @return [Object] the result of all the operations
  #
  # @raise [ArgumentError] if no block is given
  # @raise [ArgumentError] if any of the inputs are not `IVar`s
  def dataflow(*inputs, &block)
    dataflow_with(Concurrent.global_io_executor, *inputs, &block)
  end
  module_function :dataflow

  def dataflow_with(executor, *inputs, &block)
    call_dataflow(:value, executor, *inputs, &block)
  end
  module_function :dataflow_with

  def dataflow!(*inputs, &block)
    dataflow_with!(Concurrent.global_io_executor, *inputs, &block)
  end
  module_function :dataflow!

  def dataflow_with!(executor, *inputs, &block)
    call_dataflow(:value!, executor, *inputs, &block)
  end
  module_function :dataflow_with!

  private

  def call_dataflow(method, executor, *inputs)
    raise ArgumentError, 'an executor must be provided' if executor.nil?
    raise ArgumentError, 'no block given' unless block_given?
    unless inputs.all? { |input| input.is_a? IVar }
      raise ArgumentError, "Not all dependencies are IVars.\nDependencies: #{inputs.inspect}"
    end

    result = Future.new(executor: executor) do
      values = inputs.map { |input| input.send(method) }
      yield(*values)
    end

    if inputs.empty?
      result.execute
    else
      counter = DependencyCounter.new(inputs.size) { result.execute }

      inputs.each do |input|
        input.add_observer counter
      end
    end

    result
  end
  module_function :call_dataflow
end
