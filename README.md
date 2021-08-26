# Hoard

[![MIT License][license-shield]][license-url]
![Tests Status][tests-shield]


- [About](#about)
- [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Contact](#contact)


## About

The built-in serialization/deserialization functions of DragonRuby fail when used with moderately big data.

With Hoard you can serialize and deserialize arbitrarily big data without having to think about splitting them into 
manageable small pieces.


## Installation

### Via Smaug

Add following line to your `Smaug.toml`:
```toml
hoard =  "https://github.com/kfischer-okarin/hoard/releases/download/v1.0.0/hoard.zip"
```

Alternatively you can also just run `smaug add hoard` though that will add the whole repository to your project.

### Manually

Download the [current release][current-release-url], extract it,
and put the contained `lib/hoard.rb` anywhere in your game folder and require it.


## Usage

To serialize data:
```rb
serialized_data = Hoard.serialize save_game_data

# Save the data
$gtk.write_file 'saves/001.sav', serialized_data
```

To deserialize data:
```rb
serialized_data = $gtk.read_file 'saves/001.sav'

save_game_data = Hoard.deserialize serialized_data
```

### Supported Data Types
- Integers
- Strings
- Symbols
- Boolean values
- Arrays for serializable values
- Hashes with serializable keys/values

### Caution

Entities created by `args.state.new_entity` or `args.state.new_entity_strict` are serialized/deserialized as a whole.
So if a single entity is very big it could still mean that your data cannot be properly deserialized (DragonRuby will
print out a warning in that case). 

Therefore if you need to serialize huge units of data it might be better to use Hashes.

### Define your own Serializer

A serializer is a class derived from `Hoard::Serializer::BaseSerializer` that defines several class methods as below.

```rb
class MySerializer < Hoard::Serializer::BaseSerializer
  class << self
    def type
      # Return a unique symbol identifier for your serializer
    end

    def can_serialize?(value)
      # Return true if the value can be serialized by your serializer
    end

    def serialize(value)
      # Return a serialized string representation of your data
    end

    def deserialize(serialized_value)
      # Return the deserialized data
    end
  end
end
```

You can check the implementations of the [default serializers][default-serializers-source-url] if you need more details.


## Roadmap

See the [open issues][issues-url] for a list of proposed features (and known issues).


## Contributing

Thank your for your willingness to help out with the development!

If you have any contributions, please fork the repository, add your changes to a feature branch and open
a Pull Request.


## Contact

You can find me usually on the [DragonRuby Discord][dragonruby-discord-url] under the username 
`kfischer_okarin`.


[license-shield]: https://img.shields.io/github/license/kfischer-okarin/hoard
[license-url]: https://github.com/kfischer-okarin/hoard/blob/main/LICENSE
[tests-shield]: https://github.com/kfischer-okarin/hoard/actions/workflows/tests.yml/badge.svg
[current-release-url]: https://github.com/kfischer-okarin/hoard/releases/download/v1.0.0/hoard.zip
[default-serializers-source-url]: https://github.com/kfischer-okarin/hoard/tree/main/lib/hoard/serializer
[issues-url]: https://github.com/kfischer-okarin/hoard/issues
[dragonruby-discord-url]: https://discord.dragonruby.org
