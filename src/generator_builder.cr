module WordMage
  # Fluent API for configuring and building Generator instances.
  #
  # GeneratorBuilder provides a chainable interface for setting up word generation
  # with all necessary components. This makes it easy to configure complex generation
  # rules without dealing with the underlying object construction.
  #
  # ## Example
  # ```crystal
  # generator = GeneratorBuilder.create
  #   .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
  #   .with_syllable_patterns(["CV", "CVC"])
  #   .with_syllable_count(SyllableCountSpec.range(2, 4))
  #   .starting_with(:vowel)
  #   .with_constraints(["rr", "ss"])
  #   .random_mode
  #   .build
  # ```
  class GeneratorBuilder
    @phoneme_set : PhonemeSet?
    @syllable_templates : Array(SyllableTemplate)?
    @syllable_count : SyllableCountSpec?
    @starting_type : Symbol?
    @constraints : Array(String)?
    @romanizer : RomanizationMap?
    @mode : GenerationMode?
    @max_words : Int32?

    # Creates a new GeneratorBuilder instance.
    #
    # ## Returns
    # A new GeneratorBuilder ready for configuration
    def self.create
      new
    end

    # Sets the consonants and vowels for generation.
    #
    # ## Parameters
    # - `consonants`: Array of consonant phonemes
    # - `vowels`: Array of vowel phonemes
    #
    # ## Returns
    # Self for method chaining
    def with_phonemes(consonants : Array(String), vowels : Array(String))
      @phoneme_set = PhonemeSet.new(consonants.to_set, vowels.to_set)
      self
    end

    # Adds weights to phonemes for weighted sampling.
    #
    # ## Parameters
    # - `weights`: Hash mapping phonemes to their relative weights
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Must be called after `with_phonemes`
    def with_weights(weights : Hash(String, Float32))
      phoneme_set = @phoneme_set.not_nil!
      weights.each do |phoneme, weight|
        phoneme_set.add_weight(phoneme, weight)
      end
      self
    end

    # Sets syllable patterns using pattern strings.
    #
    # ## Parameters
    # - `patterns`: Array of pattern strings (e.g., ["CV", "CVC", "CCV"])
    #
    # ## Returns
    # Self for method chaining
    def with_syllable_patterns(patterns : Array(String))
      @syllable_templates = patterns.map { |p| SyllableTemplate.new(p) }
      self
    end

    # Sets syllable templates directly for advanced configuration.
    #
    # ## Parameters
    # - `templates`: Array of configured SyllableTemplate objects
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Use this for templates with custom constraints or hiatus probabilities
    def with_syllable_templates(templates : Array(SyllableTemplate))
      @syllable_templates = templates
      self
    end

    # Sets the syllable count specification.
    #
    # ## Parameters
    # - `spec`: SyllableCountSpec defining how many syllables to generate
    #
    # ## Returns
    # Self for method chaining
    def with_syllable_count(spec : SyllableCountSpec)
      @syllable_count = spec
      self
    end

    # Constrains words to start with a specific phoneme type.
    #
    # ## Parameters
    # - `type`: Either `:vowel` or `:consonant`
    #
    # ## Returns
    # Self for method chaining
    def starting_with(type : Symbol)
      @starting_type = type
      self
    end

    # Adds word-level constraints to prevent unwanted patterns.
    #
    # ## Parameters
    # - `patterns`: Array of regex patterns that words must NOT match
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_constraints(["rr", "ss", "tt"])  # No double consonants
    # ```
    def with_constraints(patterns : Array(String))
      @constraints = patterns
      self
    end

    # Sets up romanization mappings for phoneme-to-text conversion.
    #
    # ## Parameters
    # - `mappings`: Hash mapping phonemes to their written form
    #
    # ## Returns
    # Self for method chaining
    def with_romanization(mappings : Hash(String, String))
      @romanizer = RomanizationMap.new(mappings)
      self
    end

    # Sets sequential generation mode.
    #
    # ## Parameters
    # - `max_words`: Maximum number of words to generate (default: 1000)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Sequential mode generates all possible combinations systematically
    def sequential_mode(max_words : Int32 = 1000)
      @mode = GenerationMode::Sequential
      @max_words = max_words
      self
    end

    # Sets random generation mode.
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Random mode generates words using random sampling (default mode)
    def random_mode
      @mode = GenerationMode::Random
      self
    end

    # Builds the final Generator instance.
    #
    # ## Returns
    # Configured Generator ready for word generation
    #
    # ## Raises
    # Raises if required components (phonemes, syllable patterns, syllable count) are missing
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
        mode: @mode || GenerationMode::Random,
        max_words: @max_words || 1000
      )
    end
  end
end