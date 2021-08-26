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
    end
  end
end
