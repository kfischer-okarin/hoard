module Hoard
  module Serializer
    # Serializes Symbols
    class SymbolSerializer < BaseSerializer
      class << self
        def type
          :symbol
        end

        def simple?
          true
        end

        def can_serialize?(value)
          value.is_a? Symbol
        end

        def serialize(symbol)
          symbol.to_s
        end

        def deserialize(value)
          value.to_sym
        end
      end
    end
  end
end
