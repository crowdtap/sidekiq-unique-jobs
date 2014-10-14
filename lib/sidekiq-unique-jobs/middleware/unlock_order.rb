module SidekiqUniqueJobs
  module Middleware

    module UnlockOrder
      attr_reader :unlock_order

      def set_unlock_order(klass)
        @unlock_order = if unlock_order_configured?(klass)
                          klass.get_sidekiq_options['unique_unlock_order']
                        else
                          default_unlock_order
                        end
      end

      def unlock_order_configured?(klass)
        klass.respond_to?(:get_sidekiq_options) &&
          !klass.get_sidekiq_options['unique_unlock_order'].nil?
      end

      def default_unlock_order
        SidekiqUniqueJobs::Config.default_unlock_order
      end

      def before_yield?
        unlock_order == :before_yield
      end

      def after_yield?
        unlock_order == :after_yield
      end
    end
  end
end
