require 'lib/hoard/serializer.rb'

module Hoard
  class << self
    def serializers
      @serializers ||= []
    end

    def register_serializer(type, value_condition:, serialize:, type_parameters: nil, simple: false)
      serializers << Serializer::SerializerNew.new(
        type: type,
        value_condition: value_condition,
        serialize: serialize,
        type_parameters: type_parameters,
        simple: simple,
      )
    end

    def serializer_for_value(value)
      serializers.find { |serializer| serializer.can_serialize? value }
    end
  end
end
