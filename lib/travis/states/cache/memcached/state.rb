require 'json'

module Travis
  module States
    class Cache
      class Memcached
        class State < Struct.new(:client, :repo_id)
          FORMAT = :json

          attr_reader :options

          def initialize(*args)
            @options = args.last.is_a?(Hash) ? args.pop : {}
            super(*args)
          end

          def data
            @data ||= deserialize(client.get(key))
          end
          alias :read :data

          def write(state)
            client.set(key, serialize(state))
          end

          def cached?
            !!last_id
          end

          def fresh?
            last_id && build_id && build_id.to_i < last_id.to_i
          end

          def stale?
            not fresh?
          end

          def to_h
            { repo_id: repo_id, branch: branch, build_id: build_id, last_id: last_id }
          end

          private

            def branch
              options[:branch]
            end

            def build_id
              options[:build_id]
            end

            def last_id
              @last_id ||= data[:id].to_i if data
            end

            def key
              ["state:#{repo_id}", branch].compact.join('-')
            end

            def serialize(state)
              if FORMAT == :json
                JSON.dump(compact(id: build_id, state: state))
              else
                [id, state].join(':')
              end
            end

            def deserialize(value)
              return unless value
              if FORMAT == :json
                symbolize_keys(JSON.parse(value))
              else
                Hash[[:id, :state].zip(value.split(':'))]
              end
            end

            def compact(hash)
              hash.reject { |key, value| value.nil? }
            end

            def symbolize_keys(value)
              Hash[value.map { |key, value| [key.to_sym, value] }]
            end
        end
      end
    end
  end
end
