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
- **Gemination** - Configurable consonant doubling with probability control and complexity costs
- **Vowel lengthening** - Configurable vowel doubling for emphasis
- **N-gram analysis** - Comprehensive phoneme transition, bigram, and trigram frequency analysis
- **Contextual generation** - Phoneme selection based on neighboring phoneme frequencies
- **Word-initial patterns** - Special handling for word-initial phoneme selection using positional frequencies
- **Pattern-based probabilities** - Analysis-driven gemination and vowel lengthening probabilities
- **Complexity budgeting** - Gemination adds 3 complexity points to prevent overuse
- **Automatic detection** - Analyzer detects all phonological patterns in existing words
- **Statistical analysis** - Comprehensive frequency analysis of phonological features

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
12. **Analyzer** - Performs aggregate analysis across word collections with chainable API and Gusein-Zade smoothing
13. **WordAnalysis** - Data structure containing individual word metrics
14. **Analysis** - Data structure containing aggregate statistics, recommendations, and Gusein-Zade analysis
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
  - **Gemination generation** (consonant doubling with complexity costs)
  - **Vowel lengthening** (vowel doubling)
  - **N-gram analysis** (phoneme transitions, bigrams, trigrams)
  - **Contextual phoneme selection** based on neighboring frequencies
  - **Word-initial pattern handling** for realistic word beginnings
  - **Pattern-based gemination probabilities** from analysis
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
puts analysis.phoneme_transitions     # {"t" => {"ɛ" => 0.5, "n" => 0.5}}
puts analysis.most_frequent_bigrams(5) # ["tn", "nn", "ɑɑ", "ll", "ɔɔ"]
puts analysis.recommended_budget       # 8
puts analysis.recommended_gemination_probability # 0.25
```

### New Chainable Analysis API & Gusein-Zade Smoothing
```crystal
# Basic analysis (unchanged)
analysis = analyzer.analyze(words)

# Analysis with Gusein-Zade smoothing for more naturalistic frequencies
analysis = analyzer.analyze(words, true, 0.3_f32)  # 30% smoothing

# Analysis with templates using chainable API
templates = [
  WordMage::SyllableTemplate.new("CV"),
  WordMage::SyllableTemplate.new("CVC"),
  WordMage::SyllableTemplate.new("CCV", allowed_clusters: ["pr", "tr"])
]
analysis = analyzer.with_templates(templates).analyze(words)

# Analysis with both templates and Gusein-Zade smoothing
analysis = analyzer.with_templates(templates).analyze(words, true, 0.4_f32)

# Reusing analyzer with different configurations
analyzer_cv = analyzer.with_templates([WordMage::SyllableTemplate.new("CV")])
analysis1 = analyzer_cv.analyze(words)
analysis2 = analyzer_cv.analyze(words, true, 0.2_f32)

# Gusein-Zade analysis methods
weights = analysis.gusein_zade_weights           # Theoretical frequency weights
smoothed = analysis.smoothed_phoneme_frequencies # Empirical + theoretical blend
ranking = analysis.phoneme_frequency_ranking     # Phonemes by frequency
deviation = analysis.gusein_zade_deviation       # Model fit metrics
puts deviation["correlation"]  # How well empirical data fits Gusein-Zade model
```

### Analysis-Driven Generation
```crystal
# Generate words based on analysis of existing words
# Automatically detects patterns and applies them with configurable weight
target_words = ["aggon", "thaggor", "naggar", "delara"]
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "g", "r", "l"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC", "CCV"])
  .with_analysis_of_words(target_words, analysis_weight_factor: 50.0_f32)
  .with_gemination_probability(0.2_f32)  # Global multiplier for analysis patterns
  .build

word = generator.generate  # Uses detected patterns: "nagga", "thaggor", "delara"
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
- **Analytical**: Built-in analysis and detection of phonological patterns with n-gram support
- **Context-aware**: Phoneme selection considers neighboring phonemes and positional frequencies
- **Pattern-driven**: Analysis automatically informs generation probabilities and complexity costs
- **Constraint-aware**: Multiple constraints work together harmoniously
- **Input-flexible**: Methods accept both IPA strings and Phoneme instances for maximum convenience
- **Romanization-aware**: Clusters and sequences use romanized forms, not IPA symbols
- **Linguistically-grounded**: Gusein-Zade formula provides theoretically sound frequency distributions
- **Chainable**: Fluent API allows composing analysis configurations with method chaining

The library is designed to be both powerful for complex conlang needs and simple for basic word generation tasks. With the enhanced IPA phoneme system, comprehensive n-gram analysis, contextual generation, pattern-based probabilities, and Gusein-Zade smoothing, it can handle sophisticated linguistic requirements while maintaining ease of use. The chainable analysis API and analysis-driven approach allow generating words that match the phonological patterns of existing languages or word sets with theoretically grounded frequency distributions.