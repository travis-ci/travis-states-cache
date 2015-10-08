require 'json'
require 'logger'
require 'travis/states/cache/memcached'

module Travis
  class << self
    attr_accessor :states_cache
  end

  module States
    class Cache
      Error = Class.new(StandardError)

      class << self
        attr_reader :features

        def setup(config, logger = nil, features = nil)
          name  = config.delete(:adapter) || :memcached
          const = const_get(name.to_s.sub(/./, &:upcase))
          Travis.states_cache = new(const.new(config.to_h, logger))
          @features = features
        end
      end

      attr_reader :adapter

      def initialize(adapter)
        @adapter = adapter
      end

      def read_state(repo_id, options = {})
        adapter.read_state(repo_id, options) if enabled?
      end

      def read(repo_id, options = {})
        adapter.read(repo_id, options) if enabled?
      end

      def write(repo_id, state, options = {})
        adapter.write(repo_id, state, options) if enabled?
      end

      def enabled?
        features.nil? ? true : features.feature_active?(:states_cache)
      end

      private

        def features
          self.class.features
        end
    end
  end
end
