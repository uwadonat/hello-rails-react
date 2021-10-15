require 'active_support/core_ext/object/to_param'

module ActionCable
  module Channel
    module Broadcasting
      extend ActiveSupport::Concern

      delegate :broadcasting_for, to: :class

      module ClassMethods
        # Broadcast a hash to a unique broadcasting for this <tt>model</tt> in this channel.
        def broadcast_to(model, message)
          ActionCable.server.broadcast(broadcasting_for([channel_name, model]), message)
        end

        def broadcasting_for(model) #:nodoc:
          if model.is_a?(Array)
            model.map { |m| broadcasting_for(m) }.join(':')
          elsif model.respond_to?(:to_gid_param)
            model.to_gid_param
          else
            model.to_param
          end
        end
      end
    end
  end
end
