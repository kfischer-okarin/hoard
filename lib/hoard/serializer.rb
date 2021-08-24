module Hoard
  module Serializer
    class << self
      def serialize(value)
        schema = determine_schema(value)
        [
          $gtk.serialize_state(schema),
          serializer_for(schema).serialize(value)
        ].join("\n").strip
      end

      def determine_schema(value)
        simple_type = simple_value_type(value)
        return { type: simple_type } if simple_type

        case value
        when GTK::StrictEntity, GTK::OpenEntity
          { type: :entity }
        when Array
          simple_array_type = array_type(value)
          return { type: :typed_array, element_type: simple_array_type } if simple_array_type

          { type: :array, size: value.size }
        when Hash
          { type: :hash, size: value.size }
        end
      end

      def simple_value_type(value)
        case value
        when Integer
          :int
        when String
          :string
        when Symbol
          :symbol
        when true, false
          :boolean
        end
      end

      def array_type(array)
        first_element_type = simple_value_type array[0]
        return unless first_element_type
        return unless array.all? { |value| simple_value_type(value) == first_element_type }

        first_element_type
      end

      def deserialize(value)
        Deserialization.new(value).result
      end

      def serializer_for(schema)
        serializer_class(schema[:type]).new(schema)
      end

      private

      def serializer_class(type)
        SERIALIZER_CLASSES.fetch(type)
      end
    end

    class Deserialization
      attr_reader :result

      def initialize(value)
        @lines = value.split("\n")
        @index = 0
        @result = read_next_value
      end

      private

      def read_next_value
        schema = read_schema
        next_line
        read_typed_value(current_line, schema)
      end

      def read_schema
        $gtk.deserialize_state current_line
      end

      def current_line
        @lines[@index]
      end

      def next_line
        @index += 1
      end

      def read_typed_value(value, schema)
        case schema[:type]
        when :array
          [].tap { |result|
            schema[:size].times do
              result << read_next_value
            end
          }
        when :hash
          {}.tap { |result|
            schema[:size].times do
              key = read_next_value
              result[key] = read_next_value
            end
          }
        else
          Serializer.serializer_for(schema).deserialize(value).tap {
            next_line
          }
        end
      end
    end

    class BaseSerializer
      def initialize(schema)
        @schema = schema
      end
    end

    class IntSerializer < BaseSerializer
      def serialize(value)
        value.to_s
      end

      def deserialize(value)
        value.to_i
      end
    end

    class StringSerializer < BaseSerializer
      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end
    end

    class SymbolSerializer < BaseSerializer
      def serialize(value)
        value.to_s
      end

      def deserialize(value)
        value.to_sym
      end
    end

    class BooleanSerializer < BaseSerializer
      def serialize(value)
        value ? 't' : 'f'
      end

      def deserialize(value)
        value == 't'
      end
    end

    class TypedArraySerializer < BaseSerializer
      def serialize(value)
        value.map { |element|
          element_serializer.serialize(element)
        }.join(',')
      end

      def deserialize(value)
        value.split(',').map { |element|
          element_serializer.deserialize(element)
        }
      end

      private

      def element_serializer
        @element_serializer ||= Serializer.serializer_for(type: @schema[:element_type])
      end
    end

    class EntitySerializer < BaseSerializer
      def serialize(value)
        $gtk.serialize_state value
      end

      def deserialize(value)
        $gtk.deserialize_state value
      end
    end

    class ArraySerializer < BaseSerializer
      def serialize(value)
        value.map { |element|
          Serializer.serialize(element)
        }.join("\n")
      end

      def deserialize(_value)
        raise 'Should never be called'
      end
    end

    class HashSerializer < BaseSerializer
      def serialize(value)
        value.map { |key, element|
          [
            Serializer.serialize(key),
            Serializer.serialize(element)
          ].join("\n")
        }.join("\n")
      end

      def deserialize(_value)
        raise 'Should never be called'
      end
    end

    SERIALIZER_CLASSES = {
      int: IntSerializer,
      string: StringSerializer,
      symbol: SymbolSerializer,
      boolean: BooleanSerializer,
      typed_array: TypedArraySerializer,
      entity: EntitySerializer,
      array: ArraySerializer,
      hash: HashSerializer
    }
  end
end

