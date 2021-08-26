module Hoard
  module Serializer
    # Serializes Hashs sequentially by key value pair
    class HashSerializer < BaseSerializer
      class << self
        def type
          :hash
        end

        def can_serialize?(value)
          value.is_a? Hash
        end

        def type_parameters(hash)
          { size: hash.size }
        end

        def serialize(hash)
          hash.map { |key, value|
            [
              Serializers.serializer_for_value(key).serialize_with_header(key),
              Serializers.serializer_for_value(value).serialize_with_header(value)
            ]
          }
        end

        # This method reeks of :reek:DuplicateMethodCall
        # but the state of line_stream changes with every call
        # so it's ok
        def deserialize_next_value(line_stream, type_header)
          {}.tap { |result|
            type_header[:size].times do
              key = Hoard.deserialize_next_value line_stream
              result[key] = Hoard.deserialize_next_value line_stream
            end
          }
        end
      end
    end
  end
end
