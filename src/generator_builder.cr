require "./analysis"
require "./analyzer"

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
    @complexity_budget : Int32?
    @hiatus_escalation_factor : Float32?
    @vowel_harmony : VowelHarmony?

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

    # Sets the complexity budget for controlling word complexity.
    #
    # ## Parameters
    # - `budget`: Complexity budget points (typical range: 3-12)
    #   - 3-5: Simple, melodic words
    #   - 6-8: Moderate complexity
    #   - 9-12: Complex words with clusters and hiatus
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Complexity budget controls clusters, hiatus, and vowel diversity.
    # When budget is exhausted, generator creates more melodic patterns.
    def with_complexity_budget(budget : Int32)
      @complexity_budget = budget
      self
    end

    # Sets the hiatus escalation factor for controlling multiple hiatus sequences.
    #
    # ## Parameters
    # - `factor`: Escalation multiplier (typical range: 1.0-3.0)
    #   - 1.0: No escalation, all hiatus cost the same
    #   - 1.5: Moderate escalation (default)
    #   - 2.0: Strong escalation, discourages multiple hiatus
    #   - 3.0: Very strong escalation
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Each additional hiatus in a word costs progressively more:
    # 1st hiatus: 2 points, 2nd: 2×factor points, 3rd: 2×factor² points
    def with_hiatus_escalation(factor : Float32)
      @hiatus_escalation_factor = factor
      self
    end

    # Sets vowel harmony rules for the generator.
    #
    # ## Parameters
    # - `harmony`: VowelHarmony instance defining transition rules and strength
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Vowel harmony controls which vowels can follow others, from strict
    # traditional harmony (strength 1.0) to loose statistical preferences (0.1-0.5).
    def with_vowel_harmony(harmony : VowelHarmony)
      @vowel_harmony = harmony
      self
    end

    # Applies an analysis to configure the generator.
    #
    # ## Parameters
    # - `analysis`: Analysis instance containing language patterns
    # - `vowel_harmony`: Whether to apply vowel harmony (default: true)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # This method applies phoneme weights, syllable patterns, complexity budget,
    # vowel harmony, and other settings derived from the analysis.
    def with_analysis(analysis : Analysis, vowel_harmony : Bool = true)
      # Apply phoneme weights from frequency analysis
      analysis.phoneme_frequencies.each do |phoneme, frequency|
        # Convert frequency to weight (scale up for more impact)
        weight = frequency * 10.0_f32
        if @phoneme_set
          @phoneme_set.not_nil!.add_weight(phoneme, weight)
        end
      end
      
      # Apply complexity budget from analysis
      @complexity_budget = analysis.recommended_budget
      
      # Create syllable templates from recommended patterns
      if analysis.recommended_templates.size > 0
        templates = analysis.recommended_templates.map do |pattern|
          SyllableTemplate.new(pattern, hiatus_probability: analysis.recommended_hiatus_probability)
        end
        @syllable_templates = templates
      end
      
      # Apply syllable count distribution
      if analysis.syllable_count_distribution.size > 0
        @syllable_count = SyllableCountSpec.weighted(analysis.syllable_count_distribution)
      end
      
      # Apply vowel harmony if requested and available
      if vowel_harmony && !analysis.vowel_transitions.empty?
        # Use moderate strength by default, can be overridden later
        @vowel_harmony = analysis.generate_vowel_harmony(strength: 0.6_f32, threshold: 0.15_f32)
      end
      
      self
    end

    # Convenience method to analyze words and apply the results.
    #
    # ## Parameters
    # - `words`: Array of romanized words to analyze
    # - `vowel_harmony`: Whether to auto-detect and apply vowel harmony (default: true)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # This method uses the existing romanization map to analyze the words
    # and applies the results to the generator configuration, including
    # automatic vowel harmony detection.
    #
    # ## Raises
    # Raises if no romanization map has been set
    def with_analysis_of_words(words : Array(String), vowel_harmony : Bool = true)
      romanizer = @romanizer || raise "No romanization map set. Use with_romanization() first."
      
      analyzer = Analyzer.new(romanizer)
      analysis = analyzer.analyze(words)
      
      with_analysis(analysis, vowel_harmony)
    end

    # Sets vowel harmony rules for the generator.
    #
    # ## Parameters
    # - `harmony`: VowelHarmony instance defining transition rules and strength
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Vowel harmony controls which vowels can follow others, from strict
    # traditional harmony (strength 1.0) to loose statistical preferences (0.1-0.5).
    def with_vowel_harmony(harmony : VowelHarmony)
      @vowel_harmony = harmony
      self
    end

    # Toggles vowel harmony on/off or sets strength.
    #
    # ## Parameters
    # - `enabled`: Whether to enable vowel harmony
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Requires previous analysis to have been applied. If enabled is false,
    # disables vowel harmony. If true, uses the detected harmony rules.
    def with_vowel_harmony(enabled : Bool)
      if enabled
        # Keep existing harmony if available, otherwise warn
        if @vowel_harmony.nil?
          # Try to use a basic harmony if none exists
          puts "Warning: No vowel harmony rules available. Use with_analysis_of_words first."
        end
      else
        @vowel_harmony = nil
      end
      self
    end

    # Sets the vowel harmony strength/weight.
    #
    # ## Parameters
    # - `strength`: Harmony strength (0.0-1.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Requires vowel harmony to already be configured. Adjusts the strength
    # of existing harmony rules.
    def with_vowel_harmony_strength(strength : Float32)
      if harmony = @vowel_harmony
        # Create new harmony with same rules but different strength
        @vowel_harmony = VowelHarmony.new(harmony.rules, strength, harmony.default_preference)
      else
        puts "Warning: No vowel harmony rules to adjust. Use with_analysis_of_words or with_vowel_harmony first."
      end
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
        max_words: @max_words || 1000,
        complexity_budget: @complexity_budget,
        hiatus_escalation_factor: @hiatus_escalation_factor || 1.5_f32,
        vowel_harmony: @vowel_harmony
      )
    end
  end
end