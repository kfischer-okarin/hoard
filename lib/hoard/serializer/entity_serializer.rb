module Hoard
  module Serializer
    # Serializes DragonRuby entities directly
    class EntitySerializer < BaseSerializer
      class << self
        def type
          :entity
        end

        def can_serialize?(value)
          value.is_a?(GTK::StrictEntity) || value.is_a?(GTK::OpenEntity)
        end

        def serialize(entity)
          $gtk.serialize_state entity
        end

        def deserialize(value)
          $gtk.deserialize_state value
        end
      end
    end
  end
end
