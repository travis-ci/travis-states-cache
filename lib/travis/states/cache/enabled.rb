module Travis
  module States
    class Cache
      module Enabled
        attr_reader :features

        def intialize(config, options)
          @features = options[:features]
          super
        end

        def read(*)
          super if enabled?
        end

        def write(*)
          super if enabled?
        end

        private

          def enabled?
            features.nil? || features.feature_active?(:states_cache)
          end
      end
    end
  end
end
