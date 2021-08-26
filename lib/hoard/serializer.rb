require 'lib/hoard/serializer/base_serializer.rb'
require 'lib/hoard/serializer/int_serializer.rb'
require 'lib/hoard/serializer/string_serializer.rb'
require 'lib/hoard/serializer/symbol_serializer.rb'
require 'lib/hoard/serializer/boolean_serializer.rb'
require 'lib/hoard/serializer/typed_array_serializer.rb'
require 'lib/hoard/serializer/entity_serializer.rb'
require 'lib/hoard/serializer/array_serializer.rb'
require 'lib/hoard/serializer/hash_serializer.rb'

# Import default serializers here because of DragonRuby require order
require 'lib/hoard/default_serializers.rb'
