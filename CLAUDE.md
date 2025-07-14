# WordMage - Crystal Word Generation Library

## What is WordMage?

WordMage is a Crystal library for generating words for constructed languages (conlangs). It provides a flexible, phoneme-based system for creating realistic-sounding words with customizable patterns, constraints, and generation modes.

## Key Features

### Core Generation
- **Phoneme-based generation** with consonants, vowels, and positional constraints
- **IPA phoneme system** with full phonetic classification (Phoneme, Vowel, Consonant classes)
- **Flexible input handling** - methods accept both IPA strings and Phoneme instances
- **Romanized clustering** - consonant clusters configured using romanized forms, not IPA
- **Syllable templates** supporting patterns like CV, CVC, CCV with hiatus (vowel sequences)
- **Multiple generation modes**: Random, Sequential, and Weighted Random
- **Flexible syllable counts**: Exact, range, or weighted distributions
- **Romanization mapping** for converting phonemes to written form
- **Fluent builder API** for easy configuration

### Advanced Constraints
- **Thematic vowel constraints** - Force last vowel to be specific (e.g., "thranas", "kona", "tenask")
- **Sequence constraints** - Words starting/ending with specific sequences (e.g., "thra" → "thraesy", words ending in "ath")
- **Word-level constraints** to prevent unwanted phoneme sequences
- **Constraint composition** - Multiple constraints work together seamlessly

### Phonological Features
- **Gemination** - Configurable consonant doubling with probability control
- **Vowel lengthening** - Configurable vowel doubling for emphasis
- **Automatic detection** - Analyzer detects gemination and lengthening patterns in existing words
- **Statistical analysis** - Frequency analysis of phonological features

## Project Structure

```
src/
    wordmage.cr           # Main module file with requires
    phoneme_set.cr        # Phoneme management with positional rules
    syllable_template.cr  # Syllable patterns and hiatus generation
    word_spec.cr          # Word specifications and constraint validation
    romanization_map.cr   # Phoneme-to-text conversion
    generator.cr          # Main generation engine with phonological features
    generator_builder.cr  # Fluent configuration API
    word_analyzer.cr      # Individual word analysis and feature detection
    analyzer.cr           # Aggregate analysis of word collections
    word_analysis.cr      # Data structure for individual word analysis
    analysis.cr           # Data structure for aggregate analysis
    vowel_harmony.cr      # Vowel harmony rule system
    IPA/
        phoneme.cr        # Base Phoneme class with IPA symbol and romanization
        vowel.cr          # Vowel class with height, backness, rounding features
        consonant.cr      # Consonant class with manner, place, voicing features
        ipa.cr            # Complete IPA phoneme collection and utility methods

spec/
    spec_helper.cr        # Spec configuration
    wordmage_spec.cr      # Basic module tests
    phoneme_set_spec.cr   # PhonemeSet class tests
    syllable_template_spec.cr  # SyllableTemplate tests
    word_spec_spec.cr     # WordSpec and SyllableCountSpec tests
    romanization_map_spec.cr   # RomanizationMap tests
    generator_spec.cr     # Generator engine tests
    generator_builder_spec.cr  # Builder API tests
    cluster_spec.cr       # Cluster analysis tests
```

## Architecture Overview

The library follows a clean separation of concerns:

### Core Generation
1. **PhonemeSet** - Manages consonants/vowels with positional constraints and weights
2. **SyllableTemplate** - Defines syllable patterns (CV, CVC, etc.) with constraints and hiatus
3. **WordSpec** - Specifies word requirements (syllable count, constraints, thematic vowels, sequences)
4. **RomanizationMap** - Converts phonemes to written form
5. **Generator** - Main engine with phonological features (gemination, vowel lengthening)
6. **GeneratorBuilder** - Fluent API for easy configuration

### IPA Phoneme System
7. **Phoneme** - Base class for IPA phonemes with symbol and romanization
8. **Vowel** - Vowel phonemes with height, backness, rounding, and feature detection
9. **Consonant** - Consonant phonemes with manner, place, voicing, and articulatory features
10. **IPA::Utils** - Utility methods for phoneme resolution and type checking

### Analysis & Detection
11. **WordAnalyzer** - Analyzes individual words for phonological features
12. **Analyzer** - Performs aggregate analysis across word collections
13. **WordAnalysis** - Data structure containing individual word metrics
14. **Analysis** - Data structure containing aggregate statistics and recommendations
15. **VowelHarmony** - Implements vowel harmony constraint systems

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
  - **Thematic vowel constraints** ("thranas", "kona", "tenask")
  - **Sequence constraints** (starts with "thra", ends with "ath")
  - **Gemination generation** (consonant doubling)
  - **Vowel lengthening** (vowel doubling)
  - **Phonological feature detection** in analysis
  - **Complex constraint combinations**

## Running Tests

```bash
crystal spec                    # Run all tests
crystal spec spec/generator_spec.cr  # Run specific test file
```

## Example Usage

### Basic Generation
```crystal
# Generate vowel-initial words with 2-3 syllables
# Methods accept both IPA strings and Phoneme instances
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "r"], ["a", "e", "i", "o"])  # IPA strings
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .starting_with(:vowel)
  .build

word = generator.generate  # "arek", "itopa", etc.
```

### Advanced Constraints & Phonological Features
```crystal
# Generate words with complex constraints and phonological features
# Consonant clusters configured using romanized forms (not IPA)
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC", "CCV"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_thematic_vowel("a")              # Last vowel must be 'a'
  .starting_with_sequence("thr")         # Words start with "thr" (romanized)
  .ending_with_sequence("ath")           # Words end with "ath" (romanized)
  .with_gemination_probability(0.2)      # 20% consonant doubling
  .with_vowel_lengthening_probability(0.1) # 10% vowel lengthening
  .build

word = generator.generate  # "thrennorath", "thrasillath", etc.
```

### IPA Phoneme System
```crystal
# Use actual IPA Phoneme instances for precise phonetic control
require "wordmage/IPA"

# Access built-in IPA phonemes
front_vowels = WordMage::IPA::BasicPhonemes.select(&.as(WordMage::IPA::Vowel).front?)
voiced_stops = WordMage::IPA::BasicPhonemes.select do |p| 
  p.is_a?(WordMage::IPA::Consonant) && p.manner.plosive? && p.voiced
end

# Mix IPA strings and Phoneme instances
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(voiced_stops, front_vowels)  # Phoneme instances
  .with_syllable_patterns(["CV", "CVC"])
  .starting_with_sequence("br")              # Romanized cluster
  .build

# Utility methods for phoneme resolution
phoneme = WordMage::IPA::Utils.find_phoneme("t")  # Returns Consonant instance
is_vowel = WordMage::IPA::Utils.is_vowel?("a")    # Returns true
```

### Word Analysis & Detection
```crystal
# Analyze existing words for phonological patterns
romanization = {"t" => "t", "n" => "n", "a" => "ɑ", "e" => "ɛ"}
analyzer = WordMage::Analyzer.new(WordMage::RomanizationMap.new(romanization))

words = ["tenna", "kaara", "silloot", "normal"]
analysis = analyzer.analyze(words)

puts analysis.gemination_patterns      # {"nn" => 0.33, "ll" => 0.33}
puts analysis.vowel_lengthening_patterns # {"ɑɑ" => 0.67, "ɔɔ" => 0.33}
puts analysis.recommended_budget       # 8
```

### Convenience Methods
```crystal
# Enable/disable phonological features easily
# Methods accept both IPA strings and Phoneme instances
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k"], ["a", "e", "i"])  # IPA strings
  .with_syllable_patterns(["CV", "CVC"])
  .enable_gemination                    # 100% gemination
  .disable_vowel_lengthening           # 0% vowel lengthening
  .build
```

## Development Commands

```bash
crystal spec           # Run tests
crystal build src/wordmage.cr  # Build library
crystal run example.cr  # Run comprehensive examples
```

## Design Principles

- **Composable**: Each component has a single responsibility
- **Flexible**: Supports complex linguistic patterns, constraints, and phonological features
- **Testable**: Comprehensive test coverage with clear boundaries
- **Ergonomic**: Fluent API makes common tasks simple, complex tasks possible
- **Extensible**: Easy to add new patterns, constraints, and generation modes
- **Analytical**: Built-in analysis and detection of phonological patterns
- **Constraint-aware**: Multiple constraints work together harmoniously
- **Input-flexible**: Methods accept both IPA strings and Phoneme instances for maximum convenience
- **Romanization-aware**: Clusters and sequences use romanized forms, not IPA symbols

The library is designed to be both powerful for complex conlang needs and simple for basic word generation tasks. With the new IPA phoneme system, constraint framework, and phonological features, it can handle sophisticated linguistic requirements while maintaining ease of use. The dual input system (IPA strings or Phoneme instances) provides flexibility for different use cases.