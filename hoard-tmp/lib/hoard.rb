class Hoard
  INDEX_KEY = '.index'.freeze

  def initialize(directory)
    @directory = directory
    @index = self[INDEX_KEY] || []
  end

  def [](key)
    deserialized = $gtk.deserialize_state filename(key)
    return deserialized unless deserialized.is_a?(Hash) && deserialized[:serialized_class]

    serialized_class = Kernel.const_get deserialized[:serialized_class]
    serialized_class.deserialize(deserialized)
  rescue TypeError
    # Not a hash try deserializing manually
    file_content = $gtk.read_file filename(key)
    eval file_content
  rescue SyntaxError
    # Non-existing or invalid file
  end

  def []=(key, object)
    serialize_object(key, object)
    @index << key
    serialize_object(INDEX_KEY, @index)
  end

  def size
    @index.size
  end

  private

  def filename(key)
    "#{@directory}/#{key}"
  end

  def serialize_object(key, object)
    $gtk.serialize_state(filename(key), object)
  end
end

module Hoardable
  def serialize
    to_h.merge(serialized_class: self.class.name)
  end

  def to_s
    serialize.inspect
  end

  def inspect
    serialize.inspect
  end
end
