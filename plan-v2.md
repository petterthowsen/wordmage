### WordMage Architecture v2

This plan addresses the shortcomings of v1 by adding position-aware generation, constraint validation, hiatus support, and precise syllable control.

## 1. Core Phoneme System

### `PhonemeInventory`
- **Purpose**: Manage phonemes with feature-based classification
- **Attributes**:
  - `consonants : Set(String)`
  - `vowels : Set(String)`  
  - `features : Hash(String, Set(String))` # e.g., {"plosive" => ["p", "t"], "front" => ["i", "e"]}
- **Methods**:
  - `add_phoneme(phoneme : String, type : Symbol, features : Array(String))`
  - `get_by_features(features : Array(String)) : Set(String)`
  - `is_vowel?(phoneme : String) : Bool`

### `PositionalSelector`
- **Purpose**: Select phonemes based on position constraints
- **Attributes**:
  - `inventory : PhonemeInventory`
  - `position_rules : Hash(Symbol, Array(String))` # {:word_initial => ["p", "t", "k"]}
- **Methods**:
  - `select_for_position(position : Symbol, type : Symbol) : Array(String)`
  - `add_position_constraint(position : Symbol, allowed : Array(String))`

```crystal
class PositionalSelector
  def select_for_position(position : Symbol, type : Symbol) : Array(String)
    base_phonemes = case type
                   when :consonant then @inventory.consonants.to_a
                   when :vowel then @inventory.vowels.to_a
                   else [] of String
                   end
    
    if constraint = @position_rules[position]?
      base_phonemes.select { |p| constraint.includes?(p) }
    else
      base_phonemes
    end
  end
end
```

## 2. Constraint System

### `ConstraintRule`
- **Purpose**: Define phonotactic constraints
- **Attributes**:
  - `pattern : Regex`
  - `allowed : Bool`
  - `scope : Symbol` # :syllable, :word, :cluster
- **Methods**:
  - `matches?(sequence : Array(String)) : Bool`
  - `validate(sequence : Array(String)) : Bool`

### `ConstraintSystem`
- **Purpose**: Validate and enforce phonotactic rules
- **Attributes**:
  - `rules : Array(ConstraintRule)`
- **Methods**:
  - `add_rule(pattern : String, allowed : Bool, scope : Symbol)`
  - `validate_sequence(phonemes : Array(String)) : Bool`
  - `suggest_fixes(phonemes : Array(String)) : Array(Array(String))`

```crystal
class ConstraintSystem
  def validate_sequence(phonemes : Array(String)) : Bool
    @rules.all? do |rule|
      if rule.matches?(phonemes)
        rule.allowed
      else
        true
      end
    end
  end
end
```

## 3. Syllable Architecture

### `SyllableCountSpec`
- **Purpose**: Precise syllable count specification
- **Attributes**:
  - `type : Symbol` # :exact, :range, :weighted
  - `min : Int32`
  - `max : Int32`
  - `weights : Hash(Int32, Float32)?`
- **Methods**:
  - `generate_count : Int32`
  - `self.exact(count : Int32) : SyllableCountSpec`
  - `self.range(min : Int32, max : Int32) : SyllableCountSpec`

```crystal
struct SyllableCountSpec
  def self.exact(count : Int32)
    new(type: :exact, min: count, max: count)
  end
  
  def self.range(min : Int32, max : Int32)
    new(type: :range, min: min, max: max)
  end
  
  def generate_count : Int32
    case @type
    when :exact then @min
    when :range then Random.rand(@min..@max)
    when :weighted then weighted_choice
    else @min
    end
  end
end
```

### `ClusterPattern`
- **Purpose**: Advanced cluster pattern matching with restrictions
- **Attributes**:
  - `pattern : String` # "C+V" for consonant(s) + vowel
  - `restrictions : Hash(String, Array(String))` # {"V" => ["a", "o"]} - only these vowels
  - `position : Symbol` # :onset, :coda, :nucleus
  - `weight : Float32`

```crystal
class ClusterPattern
  def generate(inventory : PhonemeInventory) : Array(String)
    result = [] of String
    @pattern.each_char do |symbol|
      case symbol
      when 'C'
        allowed = get_restricted_phonemes(:consonant, inventory)
        result << allowed.sample
      when 'V'
        allowed = get_restricted_phonemes(:vowel, inventory)
        result << allowed.sample
      when '+'
        # Repeat previous type
        last_type = determine_type(result.last)
        allowed = get_restricted_phonemes(last_type, inventory)
        result << allowed.sample
      end
    end
    result
  end
  
  private def get_restricted_phonemes(type : Symbol, inventory : PhonemeInventory) : Array(String)
    base = case type
           when :consonant then inventory.consonants.to_a
           when :vowel then inventory.vowels.to_a
           else [] of String
           end
    
    if restrictions = @restrictions[type.to_s]?
      base.select { |p| restrictions.includes?(p) }
    else
      base
    end
  end
end
```

### `HiatusGenerator`
- **Purpose**: Generate vowel-vowel sequences
- **Attributes**:
  - `allowed_pairs : Array(Tuple(String, String))`
  - `probability : Float32`
- **Methods**:
  - `should_generate? : Bool`
  - `generate_hiatus : Array(String)`

```crystal
class HiatusGenerator
  def initialize(@allowed_pairs : Array(Tuple(String, String)), @probability : Float32 = 0.2)
  end
  
  def should_generate? : Bool
    Random.rand < @probability
  end
  
  def generate_hiatus : Array(String)
    pair = @allowed_pairs.sample
    [pair[0], pair[1]]
  end
end
```

## 4. Enhanced Generation System

### `SyllableGenerator`
- **Purpose**: Generate syllables with constraints
- **Attributes**:
  - `inventory : PhonemeInventory`
  - `positional_selector : PositionalSelector`
  - `cluster_patterns : Hash(Symbol, Array(ClusterPattern))`
  - `constraints : ConstraintSystem`
  - `hiatus_gen : HiatusGenerator`
- **Methods**:
  - `generate(position : Symbol = :medial) : Array(String)`
  - `generate_with_hiatus : Array(String)`

```crystal
class SyllableGenerator
  def generate(position : Symbol = :medial) : Array(String)
    syllable = [] of String
    
    # Generate onset
    if onset_pattern = select_cluster_pattern(:onset)
      onset = onset_pattern.generate(@inventory)
      # Apply positional constraints for word-initial
      if position == :initial
        onset = @positional_selector.select_for_position(:word_initial, :consonant) & onset
      end
      syllable.concat(onset) unless onset.empty?
    end
    
    # Generate nucleus (with possible hiatus)
    if @hiatus_gen.should_generate?
      nucleus = @hiatus_gen.generate_hiatus
    else
      nucleus = [@inventory.vowels.to_a.sample]
    end
    syllable.concat(nucleus)
    
    # Generate coda
    if coda_pattern = select_cluster_pattern(:coda)
      coda = coda_pattern.generate(@inventory)
      syllable.concat(coda) unless coda.empty?
    end
    
    # Validate and return
    if @constraints.validate_sequence(syllable)
      syllable
    else
      generate(position) # Retry if invalid
    end
  end
end
```

### `WordGenerator`
- **Purpose**: Generate complete words with full constraint support
- **Attributes**:
  - `syllable_generator : SyllableGenerator`
  - `count_spec : SyllableCountSpec`
  - `romanizer : RomanizationMap`
  - `word_constraints : ConstraintSystem`
- **Methods**:
  - `generate : String`
  - `generate_starting_with(type : Symbol) : String` # :vowel or :consonant

```crystal
class WordGenerator
  def generate : String
    syllable_count = @count_spec.generate_count
    syllables = [] of Array(String)
    
    (0...syllable_count).each do |i|
      position = case i
                when 0 then :initial
                when syllable_count - 1 then :final
                else :medial
                end
      syllables << @syllable_generator.generate(position)
    end
    
    phonemes = syllables.flatten
    
    # Apply word-level constraints
    if @word_constraints.validate_sequence(phonemes)
      @romanizer.romanize(phonemes)
    else
      generate # Retry if invalid
    end
  end
  
  def generate_starting_with(type : Symbol) : String
    max_attempts = 50
    attempts = 0
    
    while attempts < max_attempts
      word = generate
      first_phoneme = extract_first_phoneme(word)
      
      case type
      when :vowel
        return word if @syllable_generator.inventory.is_vowel?(first_phoneme)
      when :consonant
        return word unless @syllable_generator.inventory.is_vowel?(first_phoneme)
      end
      
      attempts += 1
    end
    
    raise "Could not generate word starting with #{type} after #{max_attempts} attempts"
  end
end
```

## 5. Configuration & Usage

### `GeneratorBuilder`
- **Purpose**: Fluent API for generator configuration
- **Methods**:
  - `with_phonemes(consonants : Array(String), vowels : Array(String))`
  - `with_syllable_count(spec : SyllableCountSpec)`
  - `allow_hiatus(probability : Float32 = 0.2)`
  - `add_cluster_pattern(position : Symbol, pattern : String, restrictions : Hash)`
  - `add_constraint(pattern : String, allowed : Bool)`
  - `build : WordGenerator`

```crystal
class GeneratorBuilder
  def self.new
    new
  end
  
  def with_phonemes(consonants : Array(String), vowels : Array(String))
    @inventory = PhonemeInventory.new(consonants, vowels)
    self
  end
  
  def with_weighted_phonemes(weights : Hash(String, Float32))
    @phoneme_weights = weights
    self
  end
  
  def with_syllable_count(spec : SyllableCountSpec)
    @count_spec = spec
    self
  end
  
  def allow_hiatus(probability : Float32 = 0.2)
    @hiatus_probability = probability
    self
  end
  
  def add_cluster_pattern(position : Symbol, pattern : String, restrictions = {} of String => Array(String))
    cluster = ClusterPattern.new(pattern: pattern, restrictions: restrictions, position: position)
    @cluster_patterns[position] ||= [] of ClusterPattern
    @cluster_patterns[position] << cluster
    self
  end
  
  def build : WordGenerator
    # Initialize all components and return configured generator
    generator = WordGenerator.new(
      syllable_generator: build_syllable_generator,
      count_spec: @count_spec,
      romanizer: @romanizer,
      word_constraints: @word_constraints
    )
    generator
  end
end
```

## 6. Sequential vs Random Generation

### `GenerationMode`
- **Purpose**: Support both sequential and random generation
- **Attributes**:
  - `type : Symbol` # :sequential, :random, :weighted_random
  - `max_words : Int32?` # For sequential mode
  - `weights : Hash(String, Float32)?` # For weighted random

### `SequentialGenerator`
- **Purpose**: Generate words in deterministic order
- **Methods**:
  - `next_word : String?` # Returns nil when exhausted
  - `reset`
  - `remaining_count : Int32`

```crystal
class SequentialGenerator
  def initialize(@base_generator : WordGenerator, @max_words : Int32 = 1000)
    @current_index = 0
    @phoneme_combinations = generate_all_combinations
  end
  
  def next_word : String?
    return nil if @current_index >= @max_words || @current_index >= @phoneme_combinations.size
    
    combination = @phoneme_combinations[@current_index]
    @current_index += 1
    @base_generator.romanizer.romanize(combination)
  end
  
  private def generate_all_combinations
    # Generate systematic combinations: ra, re, ri, ro, ta, te, ti, to, etc.
    combinations = [] of Array(String)
    # Implementation would systematically generate phoneme sequences
    combinations
  end
end
```

## 7. Usage Examples

```crystal
# Basic setup
generator = GeneratorBuilder.new
  .with_phonemes(["p", "t", "k", "s", "r"], ["a", "e", "i", "o"])
  .with_syllable_count(SyllableCountSpec.range(2, 4))
  .allow_hiatus(0.3)
  .add_cluster_pattern(:onset, "C", {} of String => Array(String))
  .add_cluster_pattern(:onset, "CC", {"V" => ["a", "o"]} of String => Array(String))  # Complex onsets with vowel restrictions
  .add_constraint("rr", false)  # No double r
  .build

# Generate different types of words
word = generator.generate                        # "satera"
vowel_start = generator.generate_starting_with(:vowel)    # "aeros"  
consonant_start = generator.generate_starting_with(:consonant)  # "pratos"

# Exact syllable count
exact_gen = GeneratorBuilder.new
  .with_phonemes(["t", "r", "s"], ["a", "e", "o"])
  .with_syllable_count(SyllableCountSpec.exact(3))
  .build

three_syllable = exact_gen.generate  # Always exactly 3 syllables

# Complex clusters with restrictions
cluster_gen = GeneratorBuilder.new
  .with_phonemes(["p", "r", "s", "t"], ["a", "e", "i", "o"])
  .add_cluster_pattern(:onset, "CCR", {"C" => ["p", "t"], "R" => ["r"], "V" => ["a", "o"]} of String => Array(String))  # "pr-" or "tr-" with "a"/"o"
  .build

# Sequential generation
sequential = SequentialGenerator.new(generator, max_words: 100)
words = [] of String
while word = sequential.next_word
  words << word  # ["ra", "re", "ri", "ro", "ta", "te", "ti", "to", "tora", "tore", ...]
end

# Weighted random generation  
weighted_gen = GeneratorBuilder.new
  .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
  .with_weighted_phonemes({"p" => 2.0, "t" => 1.0, "k" => 0.5})  # p is 2x more likely
  .build
```

## Key Improvements from v1

1. **Position-aware generation** - Handles word-initial, syllable boundaries
2. **Precise syllable control** - Exact counts vs ranges
3. **Constraint validation** - Phonotactic rule enforcement  
4. **Hiatus support** - Vowel-vowel sequences
5. **Complex cluster patterns** - Restrictions within clusters
6. **Fluent configuration** - Easy setup via builder pattern
7. **Retry logic** - Automatic regeneration when constraints violated
8. **Starting phoneme control** - Force vowel/consonant word starts

This architecture provides the flexibility needed for sophisticated word generation while maintaining clear separation of concerns and extensibility.