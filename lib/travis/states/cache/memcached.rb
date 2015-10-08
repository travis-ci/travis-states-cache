require 'travis/states/cache/memcached/state'
require 'travis/states/cache/memcached/client'

module Travis
  module States
    class Cache
      class Memcached
        MSGS = {
          write: 'Cache update: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, writing state=%{state}',
          fresh: 'Cache is fresh: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, cached build_id=%{last_id}, skipping',
          stale: 'Cache is stale: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, cached build_id=%{last_id}, writing state=%{state}',
          miss:  'Cache is missing: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, writing state=%{state}'
        }

        attr_reader :client, :logger

        def initialize(config = {}, logger = nil)
          @client = Client.new(config)
          @logger = logger || Logger.new(STDOUT)
        end

        def read_state(repo_id, options = {})
          data = fetch(repo_id, options)
          data[:state].to_sym if data && data[:state]
        end

        def read(repo_id, options = {})
          State.new(client, repo_id, options).read
        end

        def write(repo_id, state, options = {})
          force = options[:build_id].nil? || options[:force]
          obj = State.new(client, repo_id, options)
          log_info(force ? :write : cache_state(obj), obj.to_h.merge(state: state))
          obj.write(state) if force || obj.stale?
        end

        private

          def cache_state(state)
            state.fresh? ? :fresh : (state.cached? ? :stale : :miss)
          end

          def log_info(msg, args)
            logger.info("[states-cache] #{MSGS[msg] % args}")
          end
      end
    end
  end
end
