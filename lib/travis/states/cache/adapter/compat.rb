module Travis
  module States
    class Cache
      module Adapter
        module Compat
          def get(key)
            value = super
            value = try_old_format(key) unless value
            value
          end

          private

            def try_old_format(key)
              _, id, branch = *key.to_s.split(':')
              return unless branch

              value = get("state:#{id}-#{branch}")
              set(key, value) if value
              value
            end
        end
      end
    end
  end
end
