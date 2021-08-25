module Hoard
  module Serializer
    class << self
      def serialize(value)
        serializer = Hoard.serializer_for_value value
        serializer.serialize_with_header(value).join("\n").strip
      end

      def deserialize(value)
        line_stream = LineStream.new(value)
        deserialize_next_value line_stream
      end

      def deserialize_next_value(line_stream)
        type_header = $gtk.deserialize_state line_stream.read_line
        serializer = Hoard.serializer_for_type_header type_header
        serializer.deserialize_next_value(line_stream, type_header)
      end
    end

    class LineStream
      def initialize(value)
        @lines = value.split("\n")
        @index = 0
      end

      def peek_line
        @lines[@index]
      end

      def read_line
        peek_line.tap { next_line }
      end

      def next_line
        @index += 1
      end
    end

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
          call_with_one_or_two_arguments @deserialize, line_stream, type_header
        else
          deserialize line_stream.read_line, type_header
        end
      end

      def deserialize(value, type_header)
        call_with_one_or_two_arguments @deserialize, value, type_header
      end

      def type_header(value)
        { type: @type }.merge!(@type_parameters.call(value))
      end

      def call_with_one_or_two_arguments(method, argument1, argument2)
        if method.arity == 2
          method.call argument1, argument2
        else
          method.call argument1
        end
      end

      def inspect
        "Serializer(#{@type})"
      end

      def to_s
        inspect
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
                      serialize: ->(value) { value.to_s },
                      deserialize: ->(value) { value.to_i }

  register_serializer :string,
                      simple: true,
                      value_condition: ->(value) { value.is_a? String },
                      serialize: ->(value) { value },
                      deserialize: ->(value) { value }

  register_serializer :symbol,
                      simple: true,
                      value_condition: ->(value) { value.is_a? Symbol },
                      serialize: ->(value) { value.to_s },
                      deserialize: ->(value) { value.to_sym }

  register_serializer :boolean,
                      simple: true,
                      value_condition: ->(value) { [true, false].include? value },
                      serialize: ->(value) { value ? 't' : 'f' },
                      deserialize: ->(value) { value == 't' }

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
                      },
                      deserialize: lambda { |value, type_header|
                        serialized_elements = value.split(',')
                        element_type_header = { type: type_header[:element_type] }
                        serializer = Hoard.serializer_for_type_header element_type_header
                        serialized_elements.map { |element|
                          serializer.deserialize element, element_type_header
                        }
                      }

  register_serializer :entity,
                      value_condition: lambda { |value|
                        value.is_a?(GTK::StrictEntity) || value.is_a?(GTK::OpenEntity)
                      },
                      serialize: ->(entity) { $gtk.serialize_state(entity) },
                      deserialize: ->(value) { $gtk.deserialize_state(value) }

  register_serializer :array,
                      value_condition: ->(value) { value.is_a? Array },
                      type_parameters: ->(array) { { size: array.size } },
                      serialize: lambda { |array|
                        array.map { |element|
                          Hoard.serializer_for_value(element).serialize_with_header(element)
                        }
                      },
                      deserialize_from_lines: true,
                      deserialize: lambda { |line_stream, type_header|
                        [].tap { |result|
                          type_header[:size].times do
                            result << Serializer.deserialize_next_value(line_stream)
                          end
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
                      },
                      deserialize_from_lines: true,
                      deserialize: lambda { |line_stream, type_header|
                        {}.tap { |result|
                          type_header[:size].times do
                            key = Serializer.deserialize_next_value line_stream
                            result[key] = Serializer.deserialize_next_value line_stream
                          end
                        }
                      }
end
