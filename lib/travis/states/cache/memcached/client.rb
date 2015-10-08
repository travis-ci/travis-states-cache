require 'connection_pool'
require 'dalli'

module Travis
  module States
    class Cache
      class Memcached
        class Client < Struct.new(:config)
          TTL     = 7 * 24 * 60 * 60 # 7 days # TODO not used?
          POOL    = { size: 10, timeout: 3 }
          RETRIES = 3
          JITTER  = 0.5

          attr_reader :pool

          def initialize(*)
            super
            @pool = ConnectionPool.new(POOL) { config[:connection] || connection }
          end

          def get(key)
            with_memcached { |client| client.get(key) }
          end

          def set(key, value)
            with_memcached { |client| client.set(key, value) }
          end

          private

            def connection
              servers = config[:memcached_servers]
              options = config[:memcached_options] || {}
              Dalli::Client.new(servers, options.to_h)
            end

            def with_memcached
              retrying(Dalli::RingError) do
                pool.with { |client| yield client }
              end
            rescue Dalli::RingError => e
              meter('memcached.connect-errors')
              raise Error, "Couldn't connect to a memcached server: #{e.message}"
            end

            def meter(key)
              Metrics.meter(key) if defined?(Metrics)
            end

            def retrying(*exceptions)
              retries = 0
              yield
            rescue *exceptions
              raise if retries += 1 > RETRIES
              sleep interval(retries)
              retry
            end

            # Up to 1/2 * (2 ^ retries - 1) seconds. For 3 retries this means up to 3.5 seconds
            def interval(retries)
              JITTER * (rand(2 ** retries - 1) + 1)
            end
        end
      end
    end
  end
end
