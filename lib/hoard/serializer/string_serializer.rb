module Hoard
  module Serializer
    # Serializes Strings
    class StringSerializer < BaseSerializer
      class << self
        def type
          :string
        end

        def simple?
          true
        end

        def can_serialize?(value)
          value.is_a? String
        end

        def serialize(string)
          string
        end

        def deserialize(value)
          value
        end
      end
    end
  end
end
