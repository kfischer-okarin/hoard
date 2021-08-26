def test_serializer_serialize_int(_args, assert)
  expected = <<-SERIALIZED
{:type=>:int}
3
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    3,
    expected
  )
end

def test_serializer_serialize_string(_args, assert)
  expected = <<-SERIALIZED
{:type=>:string}
Rick
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    'Rick',
    expected
  )
end

def test_serializer_serialize_symbol(_args, assert)
  expected = <<-SERIALIZED
{:type=>:symbol}
hp
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    :hp,
    expected
  )
end

def test_serializer_serialize_true(_args, assert)
  expected = <<-SERIALIZED
{:type=>:boolean}
t
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    true,
    expected
  )
end

def test_serializer_serialize_false(_args, assert)
  expected = <<-SERIALIZED
{:type=>:boolean}
f
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    false,
    expected
  )
end

def test_serializer_serialize_typed_array(_args, assert)
  expected = <<-SERIALIZED
{:type=>:typed_array, :element_type=>:int}
1,2,3,4,5,6,7,8,12
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    [1, 2, 3, 4, 5, 6, 7, 8, 12],
    expected
  )
end

def test_serializer_serialize_typed_array_strings_with_comma(_args, assert)
  expected = <<-SERIALIZED
{:type=>:typed_array, :element_type=>:string}
a&comma;b,c,d
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    ['a,b', 'c', 'd'],
    expected
  )
end

def test_serializer_serialize_entity(args, assert)
  entity = args.state.new_entity_strict(:player, hp: 21, max_hp: 22)
  expected = <<-SERIALIZED
{:type=>:entity}
{:entity_id=>#{entity.entity_id}, :entity_name=>:player, :entity_type=>:player, :created_at=>-1, :global_created_at_elapsed=>-1, :entity_strict=>true, :entity_keys_by_ref=>{:entity_type=>:entity_name, :global_created_at_elapsed=>:created_at}, :hp=>21, :max_hp=>22}
SERIALIZED

  serialized = Hoard.serialize entity

  assert.equal! serialized, expected.strip, 'Serialized value was different'

  deserialized = Hoard.deserialize serialized

  assert.equal! deserialized.to_hash, entity.to_hash, 'Deserialized value was different'
end

def test_serializer_serialize_array(_args, assert)
  expected = <<-SERIALIZED
{:type=>:array, :size=>3}
{:type=>:string}
Morty
{:type=>:symbol}
somewhere
{:type=>:int}
33
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    ['Morty', :somewhere, 33],
    expected
  )
end

def test_serializer_serialize_empty_array(_args, assert)
  expected = <<-SERIALIZED
{:type=>:array, :size=>0}
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    [],
    expected
  )
end

def test_serializer_serialize_hash(_args, assert)
  expected = <<-SERIALIZED
{:type=>:hash, :size=>3}
{:type=>:symbol}
name
{:type=>:string}
Jeff
{:type=>:symbol}
combatant
{:type=>:array, :size=>2}
{:type=>:symbol}
hp
{:type=>:int}
1
{:type=>:symbol}
inventory
{:type=>:array, :size=>0}
SERIALIZED

  SerializationTest.assert_serialized_value!(
    assert,
    { name: 'Jeff', combatant: [:hp, 1], inventory: [] },
    expected
  )
end

module SerializationTest
  class << self
    def assert_serialized_value!(assert, value, expected)
      serialized = Hoard.serialize(value)

      assert.equal! serialized, expected.strip, 'Serialized value was different'

      deserialized = Hoard.deserialize serialized

      assert.equal! deserialized, value, 'Deserialized value was different'
    end
  end
end
