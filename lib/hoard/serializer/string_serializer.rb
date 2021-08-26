module Hoard
  module Serializer
    # Serializes Strings
    class StringSerializer < BaseSerializer
      class << self
        def type
          :string
        end

        def can_serialize?(value)
          value.is_a? String
        end

        def serialize(string)
          encode_newlines string
        end

        def deserialize(value)
          decode_newlines value
        end

        private

        def encode_newlines(string)
          string.gsub("\n", '&newline;')
        end

        def decode_newlines(string)
          string.gsub('&newline;', "\n")
        end
      end
    end
  end
end
