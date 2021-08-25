module Hoard
  module Serializer
    class << self
      def serialize(value)
        serializer = Hoard.serializer_for_value value
        serializer.serialize_with_header(value).join("\n").strip
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
      def deserialize(value)
        value.to_i
      end
    end

    class StringSerializer < BaseSerializer
      def deserialize(value)
        value
      end
    end

    class SymbolSerializer < BaseSerializer
      def deserialize(value)
        value.to_sym
      end
    end

    class BooleanSerializer < BaseSerializer
      def deserialize(value)
        value == 't'
      end
    end

    class TypedArraySerializer < BaseSerializer
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
      def deserialize(value)
        $gtk.deserialize_state value
      end
    end

    class ArraySerializer < BaseSerializer
      def deserialize(_value)
        raise 'Should never be called'
      end
    end

    class HashSerializer < BaseSerializer
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

    class SerializerNew
      attr_reader :type

      def initialize(type:, value_condition:, serialize:, simple:, type_parameters:)
        @type = type
        @value_condition = value_condition
        @serialize = serialize
        @simple = simple
        @type_parameters = type_parameters || ->(_) { {} }
      end

      def simple?
        @simple
      end

      def can_serialize?(value)
        @value_condition.call value
      end

      def serialize_with_header(value)
        [
          $gtk.serialize_state(type_header(value)),
          @serialize.call(value)
        ]
      end

      def serialize(value)
        @serialize.call value
      end

      def type_header(value)
        { type: @type }.merge!(@type_parameters.call(value))
      end

      def inspect
        "Serializer(#{@type})"
      end
    end

    def self.serializer_for_all_elements(collection)
      return if collection.empty?

      Hoard.serializers.find { |serializer|
        next false unless serializer.simple?

        collection.all? { |element| Hoard.serializer_for_value(element) == serializer }
      }
    end
  end

  register_serializer :int,
                      simple: true,
                      value_condition: ->(value) { value.is_a? Integer },
                      serialize: ->(value) { value.to_s }

  register_serializer :string,
                      simple: true,
                      value_condition: ->(value) { value.is_a? String },
                      serialize: ->(value) { value }

  register_serializer :symbol,
                      simple: true,
                      value_condition: ->(value) { value.is_a? Symbol },
                      serialize: ->(value) { value.to_s }

  register_serializer :boolean,
                      simple: true,
                      value_condition: ->(value) { [true, false].include? value },
                      serialize: ->(value) { value ? 't' : 'f' }

  register_serializer :typed_array,
                      value_condition: lambda { |value|
                        next false unless value.is_a? Array

                        !Serializer.serializer_for_all_elements(value).nil?
                      },
                      type_parameters: lambda { |array|
                        element_serializer = Serializer.serializer_for_all_elements array
                        element_type = element_serializer.type
                        { element_type: element_type }
                      },
                      serialize: lambda { |array|
                        serializer = Hoard.serializer_for_value array[0]
                        array.map { |element| serializer.serialize(element) }.join(',')
                      }

  register_serializer :entity,
                      value_condition: lambda { |value|
                        value.is_a?(GTK::StrictEntity) || value.is_a?(GTK::OpenEntity)
                      },
                      serialize: ->(entity) { $gtk.serialize_state(entity) }

  register_serializer :array,
                      value_condition: ->(value) { value.is_a? Array },
                      type_parameters: ->(array) { { size: array.size } },
                      serialize: lambda { |array|
                        array.map { |element|
                          Hoard.serializer_for_value(element).serialize_with_header(element)
                        }
                      }

  register_serializer :hash,
                      value_condition: ->(value) { value.is_a? Hash },
                      type_parameters: ->(hash) { { size: hash.size } },
                      serialize: lambda { |hash|
                        hash.map { |key, value|
                          [
                            Hoard.serializer_for_value(key).serialize_with_header(key),
                            Hoard.serializer_for_value(value).serialize_with_header(value)
                          ]
                        }
                      }
end
