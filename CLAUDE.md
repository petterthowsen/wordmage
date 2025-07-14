# WordMage - Crystal Word Generation Library

## What is WordMage?

WordMage is a Crystal library for generating words for constructed languages (conlangs). It provides a flexible, phoneme-based system for creating realistic-sounding words with customizable patterns, constraints, and generation modes.

## Key Features

- **Phoneme-based generation** with consonants, vowels, and positional constraints
- **Syllable templates** supporting patterns like CV, CVC, CCV with hiatus (vowel sequences)
- **Multiple generation modes**: Random, Sequential, and Weighted Random
- **Flexible syllable counts**: Exact, range, or weighted distributions
- **Word constraints** to prevent unwanted phoneme sequences
- **Romanization mapping** for converting phonemes to written form
- **Fluent builder API** for easy configuration

## Project Structure

```
src/
    wordmage.cr           # Main module file with requires
    phoneme_set.cr        # Phoneme management with positional rules
    syllable_template.cr  # Syllable patterns and hiatus generation
    word_spec.cr          # Word specifications and syllable counting
    romanization_map.cr   # Phoneme-to-text conversion
    generator.cr          # Main generation engine
    generator_builder.cr  # Fluent configuration API

spec/
    spec_helper.cr        # Spec configuration
    wordmage_spec.cr      # Basic module tests
    phoneme_set_spec.cr   # PhonemeSet class tests
    syllable_template_spec.cr  # SyllableTemplate tests
    word_spec_spec.cr     # WordSpec and SyllableCountSpec tests
    romanization_map_spec.cr   # RomanizationMap tests
    generator_spec.cr     # Generator engine tests
    generator_builder_spec.cr  # Builder API tests
```

## Architecture Overview

The library follows a clean separation of concerns:

1. **PhonemeSet** - Manages consonants/vowels with positional constraints and weights
2. **SyllableTemplate** - Defines syllable patterns (CV, CVC, etc.) with constraints and hiatus
3. **WordSpec** - Specifies word requirements (syllable count, starting type, constraints)
4. **RomanizationMap** - Converts phonemes to written form
5. **Generator** - Main engine that combines all components to generate words
6. **GeneratorBuilder** - Fluent API for easy configuration

## Test Structure

The test suite has **96 tests** covering all functionality:

- **Unit tests** for each class with comprehensive coverage
- **Integration tests** demonstrating real-world usage patterns
- **Feature tests** validating all requirements:
  - Vowel/consonant-initial words
  - Specific syllable counts (exact, range, weighted)
  - Vowel sequences (hiatus) like "taeros"
  - Consonant clusters like "spro", "spra"
  - Weighted phoneme sampling
  - Sequential vs random generation
  - Complex constraint validation

## Running Tests

```bash
crystal spec                    # Run all tests
crystal spec spec/generator_spec.cr  # Run specific test file
```

## Example Usage

```crystal
# Generate vowel-initial words with 2-3 syllables
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "r"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .starting_with(:vowel)
  .build

word = generator.generate  # "arek", "itopa", etc.
```

## Development Commands

```bash
crystal spec           # Run tests
crystal build src/wordmage.cr  # Build library
crystal run example.cr  # Run comprehensive examples
```

## Design Principles

- **Composable**: Each component has a single responsibility
- **Flexible**: Supports complex linguistic patterns and constraints
- **Testable**: Comprehensive test coverage with clear boundaries
- **Ergonomic**: Fluent API makes common tasks simple
- **Extensible**: Easy to add new patterns and generation modes

The library is designed to be both powerful for complex conlang needs and simple for basic word generation tasks.