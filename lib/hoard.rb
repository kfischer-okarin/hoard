require 'lib/hoard/line_stream.rb'
require 'lib/hoard/serializer.rb'

module Hoard
  class << self
    def serializers
      @serializers ||= []
    end

    def register_serializer(type, value_condition:, serialize:, deserialize: nil, type_parameters: nil, simple: false, deserialize_from_lines: false)
      serializers << Serializer::Serializer.new(
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
      serializers.find { |serializer| serializer.can_serialize? value }
    end

    def serializer_for_type_header(type_header)
      serializers.find { |serializer| serializer.type == type_header[:type] }
    end
  end
end
