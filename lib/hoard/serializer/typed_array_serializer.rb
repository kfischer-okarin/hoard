module Hoard
  module Serializer
    # Serializes Arrays which contain all the same type as comma separated list
    class TypedArraySerializer < BaseSerializer
      class << self
        def element_serializers
          @element_serializers ||= []
        end

        def register_element_serializer(serializer)
          element_serializers << serializer
        end

        def type
          :typed_array
        end

        def can_serialize?(value)
          return false unless value.is_a? Array

          serializer = serializer_for_all_elements value
          serializer != nil
        end

        def type_parameters(array)
          element_serializer = serializer_for_all_elements array
          element_type = element_serializer.type
          { element_type: element_type }
        end

        def serialize(array)
          serializer = Serializers.serializer_for_value array[0]
          array.map { |element| serializer.serialize(element) }.join(',')
        end

        def deserialize(value, type_header)
          serialized_elements = value.split(',')
          element_type_header = { type: type_header[:element_type] }
          serializer = Serializers.serializer_for_type_header element_type_header
          serialized_elements.map { |element|
            Util.call_according_to_arity(
              serializer.method(:deserialize),
              element,
              element_type_header
            )
          }
        end

        private

        def serializer_for_all_elements(collection)
          return if collection.empty?

          Serializers.all.find { |serializer|
            element_serializer?(serializer) && serializer.can_serialize_all_elements?(collection)
          }
        end

        def element_serializer?(serializer)
          element_serializers.include? serializer
        end
      end
    end
  end
end
