module Hoard
  module Serializer
    # Serializes Boolean values as 't' or 'f'
    class BooleanSerializer < BaseSerializer
      class << self
        def type
          :boolean
        end

        def simple?
          true
        end

        def can_serialize?(value)
          [true, false].include? value
        end

        # This method reeks of :reek:ControlParameter
        # but that can't be helped ;)
        def serialize(boolean_value)
          boolean_value ? 't' : 'f'
        end

        def deserialize(value)
          value == 't'
        end
      end
    end
  end
end
