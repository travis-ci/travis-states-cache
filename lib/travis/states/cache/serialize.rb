require 'json'
require 'travis/states/cache/serialize/compat'

module Travis
  module States
    class Cache
      module Serialize
        class String
          KEYS = [:build_id, :state]

          def serialize(data)
            data.values_at(*KEYS).join(':')
          end

          def deserialize(string)
            Hash[KEYS.zip(string.to_s.split(':').map { |value| cast(value) })]
          end

          private

            def cast(value)
              return if value == ''
              value =~ /^\d+$/ ? value.to_i : value
            end
        end

        class Json
          def serialize(data)
            JSON.dump(build_id: data[:build_id], state: data[:state])
          end

          def deserialize(string)
            symbolize_keys(JSON.parse(string.to_s)) if string
          end

          private

            def symbolize_keys(value)
              Hash[value.map { |key, value| [key.to_sym, value] }]
            end
        end

        prepend Compat

        DEFAULT_FORMAT = :string

        def serialize(data, options = {})
          serializer(options).serialize(data)
        end

        def deserialize(string)
          serializer(format: format_for(string)).deserialize(string)
        end

        def serializer(options)
          format = options[:format] || DEFAULT_FORMAT
          Serialize.const_get(format.to_s.sub(/./, &:upcase)).new
        end

        private

          def format_for(string)
            string && string.start_with?('{') ? Json : String
          end

        extend self
      end
    end
  end
end
