### WordMage Architecture v3 (Simplified)

This simplified architecture reduces complexity while maintaining all required functionality through fewer, more focused classes.

## 1. Core Classes

### `PhonemeSet`
**Purpose**: Unified phoneme management with positional constraints
**Attributes**:
- `consonants : Set(String)`
- `vowels : Set(String)`
- `position_rules : Hash(Symbol, Set(String))` # e.g., {:word_initial => ["p", "t", "k"]}
- `weights : Hash(String, Float32)` # optional phoneme weights

**Methods**:
- `add_phoneme(phoneme : String, type : Symbol, positions : Array(Symbol) = [] of Symbol)`
- `add_weight(phoneme : String, weight : Float32)`
- `get_consonants(position : Symbol? = nil) : Array(String)`
- `get_vowels(position : Symbol? = nil) : Array(String)`
- `is_vowel?(phoneme : String) : Bool`
- `sample_phoneme(type : Symbol, position : Symbol? = nil) : String`

```crystal
class PhonemeSet
  def get_consonants(position : Symbol? = nil) : Array(String)
    base = @consonants.to_a
    if position && rules = @position_rules[position]?
      base.select { |p| rules.includes?(p) }
    else
      base
    end
  end
  
  def sample_phoneme(type : Symbol, position : Symbol? = nil) : String
    candidates = case type
                 when :consonant then get_consonants(position)
                 when :vowel then get_vowels(position)
                 else [] of String
                 end
    
    if @weights.empty?
      candidates.sample
    else
      weighted_sample(candidates)
    end
  end
end
```

### `SyllableTemplate`
**Purpose**: Define syllable structure with constraints
**Attributes**:
- `pattern : String` # "CV", "CVC", "CCV", etc.
- `constraints : Array(String)` # regex patterns that must NOT match
- `hiatus_probability : Float32` # chance of V->VV
- `position_weights : Hash(Symbol, Float32)` # weight by syllable position

**Methods**:
- `generate(phonemes : PhonemeSet, position : Symbol) : Array(String)`
- `allows_hiatus? : Bool`
- `validate(syllable : Array(String)) : Bool`

```crystal
class SyllableTemplate
  def generate(phonemes : PhonemeSet, position : Symbol) : Array(String)
    syllable = [] of String
    
    @pattern.each_char do |symbol|
      case symbol
      when 'C'
        syllable << phonemes.sample_phoneme(:consonant, position)
      when 'V'
        if allows_hiatus? && Random.rand < @hiatus_probability
          syllable << phonemes.sample_phoneme(:vowel, position)
          syllable << phonemes.sample_phoneme(:vowel, position)
        else
          syllable << phonemes.sample_phoneme(:vowel, position)
        end
      end
    end
    
    # Retry if constraints violated
    if validate(syllable)
      syllable
    else
      generate(phonemes, position)
    end
  end
  
  def validate(syllable : Array(String)) : Bool
    sequence = syllable.join
    @constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
  end
end
```

### `WordSpec`
**Purpose**: Specify word generation requirements
**Attributes**:
- `syllable_count : SyllableCountSpec`
- `starting_type : Symbol?` # :vowel, :consonant, or nil (any)
- `syllable_templates : Array(SyllableTemplate)`
- `word_constraints : Array(String)` # word-level constraint patterns

**Methods**:
- `generate_syllable_count : Int32`
- `select_template(position : Symbol) : SyllableTemplate`
- `validate_word(phonemes : Array(String)) : Bool`

```crystal
struct SyllableCountSpec
  enum Type
    Exact
    Range
    Weighted
  end
  
  getter type : Type
  getter min : Int32
  getter max : Int32
  getter weights : Hash(Int32, Float32)?
  
  def self.exact(count : Int32)
    new(Type::Exact, count, count)
  end
  
  def self.range(min : Int32, max : Int32)
    new(Type::Range, min, max)
  end
  
  def generate_count : Int32
    case @type
    when .exact? then @min
    when .range? then Random.rand(@min..@max)
    when .weighted? then weighted_choice(@weights.not_nil!)
    end
  end
end
```

### `RomanizationMap`
**Purpose**: Convert phonemes to written form
**Attributes**:
- `mappings : Hash(String, String)`

**Methods**:
- `add_mapping(phoneme : String, romanization : String)`
- `romanize(phonemes : Array(String)) : String`

```crystal
class RomanizationMap
  def initialize(@mappings = {} of String => String)
  end
  
  def romanize(phonemes : Array(String)) : String
    phonemes.map { |p| @mappings[p]? || p }.join
  end
end
```

### `Generator`
**Purpose**: Main generation engine with sampling modes
**Attributes**:
- `phoneme_set : PhonemeSet`
- `word_spec : WordSpec`
- `romanizer : RomanizationMap`
- `mode : GenerationMode`

**Methods**:
- `generate : String`
- `generate_batch(count : Int32) : Array(String)`
- `next_sequential : String?` # for sequential mode
- `reset_sequential`

```crystal
enum GenerationMode
  Random
  Sequential
  WeightedRandom
end

class Generator
  def generate : String
    case @mode
    when .sequential?
      next_sequential || raise "No more sequential words available"
    else
      generate_random
    end
  end
  
  private def generate_random : String
    syllable_count = @word_spec.generate_syllable_count
    syllables = [] of Array(String)
    
    (0...syllable_count).each do |i|
      position = case i
                 when 0 then :initial
                 when syllable_count - 1 then :final
                 else :medial
                 end
      
      template = @word_spec.select_template(position)
      syllables << template.generate(@phoneme_set, position)
    end
    
    phonemes = syllables.flatten
    
    # Check word-level constraints and starting type
    if @word_spec.validate_word(phonemes) && matches_starting_type?(phonemes)
      @romanizer.romanize(phonemes)
    else
      generate_random # Retry
    end
  end
  
  private def matches_starting_type?(phonemes : Array(String)) : Bool
    return true unless starting_type = @word_spec.starting_type
    
    first_phoneme = phonemes.first?
    return false unless first_phoneme
    
    case starting_type
    when :vowel then @phoneme_set.is_vowel?(first_phoneme)
    when :consonant then !@phoneme_set.is_vowel?(first_phoneme)
    else true
    end
  end
end
```

## 2. Builder Pattern

### `GeneratorBuilder`
**Purpose**: Fluent configuration API
```crystal
class GeneratorBuilder
  def self.create
    new
  end
  
  def with_phonemes(consonants : Array(String), vowels : Array(String))
    @phoneme_set = PhonemeSet.new(consonants.to_set, vowels.to_set)
    self
  end
  
  def with_weights(weights : Hash(String, Float32))
    @phoneme_set.not_nil!.weights = weights
    self
  end
  
  def with_syllable_patterns(patterns : Array(String))
    @syllable_templates = patterns.map { |p| SyllableTemplate.new(p) }
    self
  end
  
  def with_syllable_count(spec : SyllableCountSpec)
    @syllable_count = spec
    self
  end
  
  def starting_with(type : Symbol)
    @starting_type = type
    self
  end
  
  def with_constraints(patterns : Array(String))
    @constraints = patterns
    self
  end
  
  def with_romanization(mappings : Hash(String, String))
    @romanizer = RomanizationMap.new(mappings)
    self
  end
  
  def sequential_mode(max_words : Int32 = 1000)
    @mode = GenerationMode::Sequential
    @max_words = max_words
    self
  end
  
  def random_mode
    @mode = GenerationMode::Random
    self
  end
  
  def build : Generator
    word_spec = WordSpec.new(
      syllable_count: @syllable_count.not_nil!,
      starting_type: @starting_type,
      syllable_templates: @syllable_templates.not_nil!,
      word_constraints: @constraints || [] of String
    )
    
    Generator.new(
      phoneme_set: @phoneme_set.not_nil!,
      word_spec: word_spec,
      romanizer: @romanizer || RomanizationMap.new,
      mode: @mode || GenerationMode::Random
    )
  end
end
```

## 3. Usage Examples

```crystal
# Basic word generation
generator = GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "s", "r"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(SyllableCountSpec.range(2, 4))
  .with_romanization({"p" => "p", "t" => "t", "a" => "a"}) # 1:1 mapping
  .build

word = generator.generate # "taros"

# Vowel-initial words
vowel_gen = GeneratorBuilder.create
  .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
  .with_syllable_patterns(["V", "CV", "CVC"])
  .starting_with(:vowel)
  .build

vowel_word = vowel_gen.generate # "atek"

# Sequential generation
sequential = GeneratorBuilder.create
  .with_phonemes(["r", "t"], ["a", "e"])
  .with_syllable_patterns(["CV"])
  .with_syllable_count(SyllableCountSpec.exact(1))
  .sequential_mode(8)
  .build

words = [] of String
while word = sequential.next_sequential
  words << word
end
# words = ["ra", "re", "ta", "te"]

# Weighted phonemes
weighted = GeneratorBuilder.create
  .with_phonemes(["p", "t", "k"], ["a", "e"])
  .with_weights({"p" => 2.0, "t" => 1.0, "k" => 0.5, "a" => 1.5, "e" => 1.0})
  .with_syllable_patterns(["CV"])
  .build

# Complex constraints
constrained = GeneratorBuilder.create
  .with_phonemes(["p", "t", "r", "s"], ["a", "e", "o"])
  .with_syllable_patterns(["CCV", "CV"]) # Allow clusters
  .with_constraints(["rr", "ss"]) # No double consonants
  .build
```

## Key Simplifications

1. **Merged `PhonemeInventory` + `PositionalSelector`** → **`PhonemeSet`**
2. **Merged `ConstraintRule` + `ConstraintSystem`** → **Simple string patterns in templates**
3. **Merged `ClusterPattern` + `HiatusGenerator`** → **Pattern strings with hiatus probability**
4. **Simplified generation** → **Single `Generator` class handles all modes**
5. **Clearer responsibilities** → **Each class has one focused purpose**

This architecture maintains all required functionality while being much easier to understand and implement.