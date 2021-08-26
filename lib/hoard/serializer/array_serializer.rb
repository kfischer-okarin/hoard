module Hoard
  module Serializer
    # Serializes Arrays sequentially element by element
    class ArraySerializer < BaseSerializer
      class << self
        def type
          :array
        end

        def can_serialize?(value)
          value.is_a? Array
        end

        def type_parameters(array)
          { size: array.size }
        end

        def serialize(array)
          array.map { |element|
            Serializers.serializer_for_value(element).serialize_with_header(element)
          }
        end

        def deserialize_next_value(line_stream, type_header)
          [].tap { |result|
            type_header[:size].times do
              result << Hoard.deserialize_next_value(line_stream)
            end
          }
        end
      end
    end
  end
end
