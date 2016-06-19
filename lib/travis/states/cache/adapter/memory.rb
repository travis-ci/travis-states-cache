module Travis
  module States
    class Cache
      module Adapter
        class Memory
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
      end
    end
  end
end
