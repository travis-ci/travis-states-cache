require 'logger'
require 'travis/states/cache/adapter/memcached'
require 'travis/states/cache/adapter/memory'
require 'travis/states/cache/enabled'
require 'travis/states/cache/record'
require 'travis/states/cache/serialize'

module Travis
  module States
    class Cache
      MSGS = {
        fresh: 'Cache is fresh: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, cached build_id=%{cached_build_id}, skipping',
        stale: 'Cache is stale: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, cached build_id=%{cached_build_id}, writing state=%{state}',
        miss:  'Cache is missing: repo_id=%{repo_id} branch=%{branch}, given build_id=%{build_id}, writing state=%{state}',
        flush: 'Flushing states cache'
      }

      prepend Enabled

      Error = Class.new(StandardError)

      attr_reader :adapter, :logger

      def initialize(config, options = {})
        @logger  = options[:logger] || Logger.new(STDOUT)
        @adapter = adapter_for(config.to_h)
      end

      def read(args, &block)
        record = Record.new(adapter, args)
        return record.state if record.fresh?
        record.write(block.call(args)) if block
        record.state
      end

      def write(state, args)
        record = Record.new(adapter, args)
        info write_msg(record.status, state, record.to_h)
        record.write(state) && record.state unless record.fresh?
      end

      def flush
        info MSGS[:flush]
        adapter.flush
      end

      private

        def write_msg(msg, state, args)
          MSGS[msg] % args.merge(state: state)
        end

        def info(msg)
          logger.info "[states-cache] #{msg}"
        end

        def adapter_for(config)
          name  = config.delete(:adapter) || :memcached
          const = Adapter.const_get(name.to_s.sub(/./, &:upcase))
          const.new(config.to_h, logger)
        end
    end
  end
end
