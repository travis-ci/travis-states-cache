require 'travis/states/cache/serialize'

module Travis
  module States
    class Cache
      class Record < Struct.new(:store, :args, :options)
        include Serialize

        def read
          @data ||= deserialize(store.get(key), options)
        end

        def write(state)
          @data = args.merge(state: state)
          store.set(key, serialize(read, options))
          read
        end

        def state
          read[:state].to_sym if read[:state]
        end

        def status
          fresh? ? :fresh : cached? ? :stale : :miss
        end

        def cached?
          !!read[:state]
        end

        def fresh?
          cached? && build_id.to_i <= read[:build_id].to_i
        end

        def to_h
          { repo_id: repo_id, branch: branch, build_id: build_id, cached_build_id: read[:build_id] }
        end

        private

          [:repo_id, :branch, :build_id].each do |name|
            define_method(name) { args[name] }
          end

          def key
            ['state', repo_id, branch].compact.join(':')
          end
      end
    end
  end
end
