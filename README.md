# wordmage

WordMage is a Crystal library for generating words for constructed languages (conlangs). It provides a flexible, phoneme-based system for creating realistic-sounding words with customizable patterns, constraints, and generation modes.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     wordmage:
       github: petterthowsen/wordmage
   ```

2. Run `shards install`

## Usage

```crystal
require "wordmage"
puts "=== Words starting with vowels ==="
vowel_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "r"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["V", "CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .starting_with(:vowel)
  .build

5.times do
  puts vowel_gen.generate
end
```

## Development
see [CLAUDE.md](CLAUDE.md)


## Contributing

1. Fork it (<https://github.com/petterthowsen/wordmage/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Petter Thowsen](https://github.com/petterthowsen) - creator and maintainer
