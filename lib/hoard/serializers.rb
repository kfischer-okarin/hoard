module Hoard
  # Manages serializer registration
  module Serializers
    class << self
      def all
        @all ||= []
      end

      def register(serializer)
        all << serializer
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
