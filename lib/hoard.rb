require 'lib/hoard/util.rb'
require 'lib/hoard/line_stream.rb'
require 'lib/hoard/serializers.rb'
require 'lib/hoard/serializer.rb'

module Hoard
  class << self
    def serialize(value)
      serializer = Serializers.serializer_for_value value
      serializer.serialize_with_header(value).join("\n").strip
    end

    def deserialize(value)
      line_stream = LineStream.new(value)
      deserialize_next_value line_stream
    end

    def deserialize_next_value(line_stream)
      type_header = $gtk.deserialize_state line_stream.read_line
      serializer = Serializers.serializer_for_type_header type_header
      serializer.deserialize_next_value(line_stream, type_header)
    end
  end
end
