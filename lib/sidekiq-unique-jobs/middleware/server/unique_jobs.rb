require 'digest'
require 'sidekiq-unique-jobs/middleware/unlock_order'

module SidekiqUniqueJobs
  module Middleware
    module Server
      class UniqueJobs
        include SidekiqUniqueJobs::Middleware::UnlockOrder

        attr_reader :redis_pool

        def call(worker, item, queue, redis_pool = nil)
          @redis_pool = redis_pool

          set_unlock_order(worker.class)
          lock_key = payload_hash(item)
          unlocked = before_yield? ? unlock(lock_key).inspect : 0

          yield
        ensure
          if after_yield? || !defined? unlocked || unlocked != 1
            unlock(lock_key)
          end
        end

        protected

        def payload_hash(item)
          SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])
        end

        def unlock(payload_hash)
          if redis_pool
            redis_pool.with { |conn| conn.del(payload_hash) }
          else
            Sidekiq.redis { |conn| conn.del(payload_hash) }
          end
        end

        def logger
          Sidekiq.logger
        end
      end
    end
  end
end
