require 'forwardable'
require 'travis/states/cache/adapter/compat'

module Travis
  module States
    class Cache
      module Adapter
        class Memory
          class Client
            attr_reader :data

            def initialize(*)
              @data = {}
            end

            def get(key)
              data[key]
            end

            def set(key, value)
              data[key] = value
            end

            def flush
              @data = {}
            end
          end

          extend Forwardable
          prepend Compat

          attr_reader :client
          def_delegators :client, :get, :set, :flush

          def initialize(*)
            @client = Client.new
          end
        end
      end
    end
  end
end
