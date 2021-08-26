module Hoard
  # Serializes and deserializes values
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
