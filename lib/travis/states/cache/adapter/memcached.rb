require 'connection_pool'
require 'dalli'
require 'travis/states/cache/adapter/compat'

module Travis
  module States
    class Cache
      module Adapter
        class Memcached
          TTL     = 7 * 24 * 60 * 60 # 7 days # TODO not used?
          POOL    = { size: 10, timeout: 3 }
          RETRIES = 3
          JITTER  = 0.5

          prepend Compat

          attr_reader :config, :pool, :client

          def initialize(config = {}, options = {})
            @config = config
            # TODO normalize these configs
            @client = Dalli::Client.new(config[:memcached_servers], (config[:memcached_options] || {}).to_h)
            @pool = ConnectionPool.new(POOL) { client }
          end

          def get(key)
            with_memcached { |client| client.get(key) }
          end

          def set(key, value)
            with_memcached { |client| client.set(key, value) }
          end

          def flush
            with_memcached { |client| client.flush }
          end

          private

            def with_memcached
              retrying { pool.with { |client| yield client } }
            rescue Dalli::RingError => e
              meter('memcached.connect-errors')
              raise Error, "Could not connect to a memcached server: #{e.message}"
            end

            def meter(key)
              options[:metrics].meter(key) if options[:metrics]
            end

            def retrying(*exceptions)
              retries = 0
              yield
            rescue Dalli::RingError
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
