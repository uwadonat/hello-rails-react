module ActionCable
  module Server
    class Worker
      module ActiveRecordConnectionManagement
        extend ActiveSupport::Concern

        included do
          set_callback :work, :around, :with_database_connections if defined?(ActiveRecord::Base)
        end

        def with_database_connections
          connection.logger.tag(ActiveRecord::Base.logger) { yield }
        end
      end
    end
  end
end
