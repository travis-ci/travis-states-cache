module Travis
  module States
    class Cache
      module Serialize
        module Compat
          def deserialize(string)
            data = super
            data[:build_id] = data.delete(:id) if data.key?(:id)
            data
          end
        end
      end
    end
  end
end
