Hoard::Serializers.register :int,
                            simple: true,
                            value_condition: ->(value) { value.is_a? Integer },
                            serialize: ->(value) { value.to_s },
                            deserialize: ->(value) { value.to_i }

Hoard::Serializers.register :string,
                            simple: true,
                            value_condition: ->(value) { value.is_a? String },
                            serialize: ->(value) { value },
                            deserialize: ->(value) { value }

Hoard::Serializers.register :symbol,
                            simple: true,
                            value_condition: ->(value) { value.is_a? Symbol },
                            serialize: ->(value) { value.to_s },
                            deserialize: ->(value) { value.to_sym }

Hoard::Serializers.register :boolean,
                            simple: true,
                            value_condition: ->(value) { [true, false].include? value },
                            serialize: ->(value) { value ? 't' : 'f' },
                            deserialize: ->(value) { value == 't' }

Hoard::Serializers.register :typed_array,
                            value_condition: lambda { |value|
                              next false unless value.is_a? Array

                              !Hoard::Serializers.serializer_for_all_elements(value).nil?
                            },
                            type_parameters: lambda { |array|
                              element_serializer = Hoard::Serializers.serializer_for_all_elements array
                              element_type = element_serializer.type
                              { element_type: element_type }
                            },
                            serialize: lambda { |array|
                              serializer = Hoard::Serializers.serializer_for_value array[0]
                              array.map { |element| serializer.serialize(element) }.join(',')
                            },
                            deserialize: lambda { |value, type_header|
                              serialized_elements = value.split(',')
                              element_type_header = { type: type_header[:element_type] }
                              serializer = Hoard::Serializers.serializer_for_type_header element_type_header
                              serialized_elements.map { |element|
                                serializer.deserialize element, element_type_header
                              }
                            }

Hoard::Serializers.register :entity,
                            value_condition: lambda { |value|
                              value.is_a?(GTK::StrictEntity) || value.is_a?(GTK::OpenEntity)
                            },
                            serialize: ->(entity) { $gtk.serialize_state(entity) },
                            deserialize: ->(value) { $gtk.deserialize_state(value) }

Hoard::Serializers.register :array,
                            value_condition: ->(value) { value.is_a? Array },
                            type_parameters: ->(array) { { size: array.size } },
                            serialize: lambda { |array|
                              array.map { |element|
                                Hoard::Serializers.serializer_for_value(element).serialize_with_header(element)
                              }
                            },
                            deserialize_from_lines: true,
                            deserialize: lambda { |line_stream, type_header|
                              [].tap { |result|
                                type_header[:size].times do
                                  result << Hoard.deserialize_next_value(line_stream)
                                end
                              }
                            }

Hoard::Serializers.register :hash,
                            value_condition: ->(value) { value.is_a? Hash },
                            type_parameters: ->(hash) { { size: hash.size } },
                            serialize: lambda { |hash|
                              hash.map { |key, value|
                                [
                                  Hoard::Serializers.serializer_for_value(key).serialize_with_header(key),
                                  Hoard::Serializers.serializer_for_value(value).serialize_with_header(value)
                                ]
                              }
                            },
                            deserialize_from_lines: true,
                            deserialize: lambda { |line_stream, type_header|
                              {}.tap { |result|
                                type_header[:size].times do
                                  key = Hoard.deserialize_next_value line_stream
                                  result[key] = Hoard.deserialize_next_value line_stream
                                end
                              }
                            }
