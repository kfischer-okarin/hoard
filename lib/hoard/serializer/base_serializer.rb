module Hoard
  module Serializer
    # Base class for serializers
    class BaseSerializer
      class << self
        def can_serialize_all_elements?(collection)
          collection.all? { |element| can_serialize?(element) }
        end

        def serialize_with_header(value)
          [
            $gtk.serialize_state(type_header(value)),
            serialize(value)
          ]
        end

        def type_header(value)
          { type: type }.merge!(type_parameters(value))
        end

        def type_parameters(_value)
          {}
        end

        def deserialize_next_value(line_stream, type_header)
          Util.call_according_to_arity method(:deserialize), line_stream.read_line, type_header
        end
      end
    end
  end
end
