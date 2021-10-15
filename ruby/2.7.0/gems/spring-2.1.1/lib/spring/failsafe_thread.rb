require 'thread'

module Spring
  class << self
    def failsafe_thread
      Thread.new do
        begin
          yield
        rescue StandardError
        end
      end
    end
  end
end
