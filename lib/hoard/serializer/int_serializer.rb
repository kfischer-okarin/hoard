module Hoard
  module Serializer
    # Serializes Integers
    class IntSerializer < BaseSerializer
      class << self
        def type
          :int
        end

        def can_serialize?(value)
          value.is_a? Integer
        end

        def serialize(integer)
          integer.to_s
        end

        def deserialize(value)
          value.to_i
        end
      end
    end
  end
end
