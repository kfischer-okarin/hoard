module Hoard
  module Serializer
    class Serializer
      attr_reader :type

      def initialize(type:, value_condition:, serialize:, deserialize:, type_parameters:, simple:, deserialize_from_lines:)
        @type = type
        @value_condition = value_condition
        @serialize = serialize
        @deserialize = deserialize
        @type_parameters = type_parameters || ->(_) { {} }
        @simple = simple
        @deserialize_from_lines = deserialize_from_lines
      end

      def simple?
        @simple
      end

      def can_serialize?(value)
        @value_condition.call value
      end

      def can_serialize_all_elements?(collection)
        collection.all? { |element| can_serialize?(element) }
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

      def deserialize_next_value(line_stream, type_header)
        if @deserialize_from_lines
          Util.call_according_to_arity @deserialize, line_stream, type_header
        else
          deserialize line_stream.read_line, type_header
        end
      end

      def deserialize(value, type_header)
        Util.call_according_to_arity @deserialize, value, type_header
      end

      def type_header(value)
        { type: @type }.merge!(@type_parameters.call(value))
      end

      def inspect
        "Serializer(#{@type})"
      end

      def to_s
        inspect
      end
    end
  end

  Serializers.register :int,
                       simple: true,
                       value_condition: ->(value) { value.is_a? Integer },
                       serialize: ->(value) { value.to_s },
                       deserialize: ->(value) { value.to_i }

  Serializers.register :string,
                       simple: true,
                       value_condition: ->(value) { value.is_a? String },
                       serialize: ->(value) { value },
                       deserialize: ->(value) { value }

  Serializers.register :symbol,
                       simple: true,
                       value_condition: ->(value) { value.is_a? Symbol },
                       serialize: ->(value) { value.to_s },
                       deserialize: ->(value) { value.to_sym }

  Serializers.register :boolean,
                       simple: true,
                       value_condition: ->(value) { [true, false].include? value },
                       serialize: ->(value) { value ? 't' : 'f' },
                       deserialize: ->(value) { value == 't' }

  Serializers.register :typed_array,
                       value_condition: lambda { |value|
                         next false unless value.is_a? Array

                         !Serializers.serializer_for_all_elements(value).nil?
                       },
                       type_parameters: lambda { |array|
                         element_serializer = Serializers.serializer_for_all_elements array
                         element_type = element_serializer.type
                         { element_type: element_type }
                       },
                       serialize: lambda { |array|
                         serializer = Serializers.serializer_for_value array[0]
                         array.map { |element| serializer.serialize(element) }.join(',')
                       },
                       deserialize: lambda { |value, type_header|
                         serialized_elements = value.split(',')
                         element_type_header = { type: type_header[:element_type] }
                         serializer = Serializers.serializer_for_type_header element_type_header
                         serialized_elements.map { |element|
                           serializer.deserialize element, element_type_header
                         }
                       }

  Serializers.register :entity,
                       value_condition: lambda { |value|
                         value.is_a?(GTK::StrictEntity) || value.is_a?(GTK::OpenEntity)
                       },
                       serialize: ->(entity) { $gtk.serialize_state(entity) },
                       deserialize: ->(value) { $gtk.deserialize_state(value) }

  Serializers.register :array,
                       value_condition: ->(value) { value.is_a? Array },
                       type_parameters: ->(array) { { size: array.size } },
                       serialize: lambda { |array|
                         array.map { |element|
                           Serializers.serializer_for_value(element).serialize_with_header(element)
                         }
                       },
                       deserialize_from_lines: true,
                       deserialize: lambda { |line_stream, type_header|
                         [].tap { |result|
                           type_header[:size].times do
                             result << Hoard.deserialize_next_value(line_stream)
                           end
                         }
                       }

  Serializers.register :hash,
                       value_condition: ->(value) { value.is_a? Hash },
                       type_parameters: ->(hash) { { size: hash.size } },
                       serialize: lambda { |hash|
                         hash.map { |key, value|
                           [
                             Serializers.serializer_for_value(key).serialize_with_header(key),
                             Serializers.serializer_for_value(value).serialize_with_header(value)
                           ]
                         }
                       },
                       deserialize_from_lines: true,
                       deserialize: lambda { |line_stream, type_header|
                         {}.tap { |result|
                           type_header[:size].times do
                             key = Hoard.deserialize_next_value line_stream
                             result[key] = Hoard.deserialize_next_value line_stream
                           end
                         }
                       }
end
