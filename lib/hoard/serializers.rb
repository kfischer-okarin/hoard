module Hoard
  # Manages serializer registration
  module Serializers
    class << self
      def all
        @all ||= []
      end

      def register(type, value_condition:, serialize:, deserialize: nil, type_parameters: nil, simple: false, deserialize_from_lines: false)
        all << Serializer::Serializer.new(
          type: type,
          value_condition: value_condition,
          serialize: serialize,
          deserialize: deserialize,
          type_parameters: type_parameters,
          simple: simple,
          deserialize_from_lines: deserialize_from_lines
        )
      end

      def serializer_for_value(value)
        all.find { |serializer| serializer.can_serialize? value }
      end

      def serializer_for_type_header(type_header)
        all.find { |serializer| serializer.type == type_header[:type] }
      end

      def serializer_for_all_elements(collection)
        return if collection.empty?

        all.find { |serializer|
          serializer.simple? && serializer.can_serialize_all_elements?(collection)
        }
      end
    end
  end
end
