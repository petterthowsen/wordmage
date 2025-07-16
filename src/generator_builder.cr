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
    @thematic_vowel : String?
    @starts_with : String?
    @ends_with : String?
    @gemination_probability : Float32?
    @vowel_lengthening_probability : Float32?
    @analysis_weight_factor : Float32?
    @phoneme_transitions : Hash(String, Hash(String, Float32))?
    @transition_weight_factor : Float32?
    @positional_frequencies : Hash(String, Hash(String, Float32))?
    @gemination_patterns : Hash(String, Float32)?
    @vowel_lengthening_patterns : Hash(String, Float32)?
    
    # Configurable complexity costs
    @cluster_cost : Float32?
    @hiatus_cost : Float32?
    @complex_coda_cost : Float32?
    @gemination_cost : Float32?
    @vowel_lengthening_cost : Float32?

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
    # - `consonants`: Array of consonant phonemes (strings or IPA::Phoneme instances)
    # - `vowels`: Array of vowel phonemes (strings or IPA::Phoneme instances)
    #
    # ## Returns
    # Self for method chaining
    def with_phonemes(consonants : Array(String | IPA::Phoneme), vowels : Array(String | IPA::Phoneme))
      @phoneme_set = PhonemeSet.new(consonants, vowels)
      self
    end

    # Backward compatibility overload for strings only
    def with_phonemes(consonants : Array(String), vowels : Array(String))
      @phoneme_set = PhonemeSet.new(consonants.map(&.as(String | IPA::Phoneme)), vowels.map(&.as(String | IPA::Phoneme)))
      self
    end

    # Sets the phonemes by group i:E {'C' => ["b", "p"...], ...}
    #
    # ## Returns
    # Self for method chaining
    def with_phonemes(grouped_phonemes : Hash(Char, Array(String | IPA::Phoneme)))
      @phoneme_set = PhonemeSet.new(grouped_phonemes)
      self
    end

    # Adds weights to phonemes for weighted sampling.
    #
    # ## Parameters
    # - `weights`: Hash mapping phonemes (strings or IPA::Phoneme instances) to their relative weights
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Note
    # Must be called after `with_phonemes`
    def with_weights(weights : Hash(String | IPA::Phoneme, Float32))
      phoneme_set = @phoneme_set.not_nil!
      weights.each do |phoneme, weight|
        phoneme_set.add_weight(phoneme, weight)
      end
      self
    end

    # Backward compatibility overload for strings only
    def with_weights(weights : Hash(String, Float32))
      phoneme_set = @phoneme_set.not_nil!
      weights.each do |phoneme, weight|
        phoneme_set.add_weight(phoneme, weight)
      end
      self
    end

    # Adds a custom phoneme group for pattern generation.
    #
    # ## Parameters
    # - `symbol`: Single character symbol for the group (e.g., 'F' for fricatives)
    # - `phonemes`: Array of phonemes (strings or IPA::Phoneme instances) belonging to this group
    # - `positions`: Optional array of position symbols for positional constraints
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # generator = GeneratorBuilder.create
    #   .with_phonemes(["p", "t", "k", "f", "s"], ["a", "e", "i"])
    #   .with_custom_group('F', ["f", "s"])  # Fricatives
    #   .with_custom_group('P', ["p", "t", "k"])  # Plosives  
    #   .with_syllable_patterns(["FVC", "PVF"])  # Use custom groups in patterns
    #   .build
    # ```
    #
    # ## Note
    # Must be called after `with_phonemes`
    def with_custom_group(symbol : Char, phonemes : Array(String | IPA::Phoneme), positions : Array(Symbol) = [] of Symbol)
      phoneme_set = @phoneme_set.not_nil!
      phoneme_set.add_custom_group(symbol, phonemes, positions)
      self
    end

    # Backward compatibility overload for strings only
    def with_custom_group(symbol : Char, phonemes : Array(String), positions : Array(Symbol) = [] of Symbol)
      phoneme_set = @phoneme_set.not_nil!
      phoneme_set.add_custom_group(symbol, phonemes.map(&.as(String | IPA::Phoneme)), positions)
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

    # Sets syllable patterns with custom probabilities.
    #
    # ## Parameters
    # - `patterns_with_probabilities`: Hash mapping pattern strings to their relative probabilities
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_syllable_pattern_probabilities({
    #   "CV" => 3.0,   # CV patterns are 3x more likely
    #   "CVC" => 2.0,  # CVC patterns are 2x more likely
    #   "CCV" => 1.0   # CCV patterns have baseline probability
    # })
    # ```
    def with_syllable_pattern_probabilities(patterns_with_probabilities : Hash(String, Float32))
      @syllable_templates = patterns_with_probabilities.map { |pattern, probability| 
        SyllableTemplate.new(pattern, probability: probability) 
      }
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
    def with_analysis(analysis : Analysis, vowel_harmony : Bool = true, analysis_weight_factor : Float32 = 20.0_f32)
      # Apply phoneme weights from frequency analysis
      analysis.phoneme_frequencies.each do |phoneme, frequency|
        # Convert frequency to weight (scale up for more impact)
        weight = frequency * analysis_weight_factor
        if @phoneme_set
          @phoneme_set.not_nil!.add_weight(phoneme, weight)
        end
      end
      
      # Apply complexity budget from analysis
      @complexity_budget = analysis.recommended_budget
      
      # Create syllable templates from recommended patterns (only if none are already defined)
      if analysis.recommended_templates.size > 0 && @syllable_templates.nil?
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
      
      # Apply phoneme transitions for contextual generation
      if !analysis.phoneme_transitions.empty?
        @phoneme_transitions = analysis.phoneme_transitions
        @transition_weight_factor = analysis_weight_factor * 0.1_f32  # Scale down for transitions
      end
      
      # Apply positional frequencies for word-initial selection
      if !analysis.positional_frequencies.empty?
        @positional_frequencies = analysis.positional_frequencies
      end
      
      # Apply gemination patterns
      if !analysis.gemination_patterns.empty?
        @gemination_patterns = analysis.gemination_patterns
      end
      
      # Apply vowel lengthening patterns
      if !analysis.vowel_lengthening_patterns.empty?
        @vowel_lengthening_patterns = analysis.vowel_lengthening_patterns
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
    def with_analysis_of_words(words : Array(String), vowel_harmony : Bool = true, analysis_weight_factor : Float32 = 20.0_f32)
      romanizer = @romanizer || raise "No romanization map set. Use with_romanization() first."
      
      analyzer = Analyzer.new(romanizer)
      analysis = analyzer.analyze(words)
      
      with_analysis(analysis, vowel_harmony, analysis_weight_factor)
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

    # Sets a thematic vowel constraint forcing the last vowel to be specific.
    #
    # ## Parameters
    # - `vowel`: The phoneme (string or IPA::Phoneme instance) that must be the last vowel in generated words
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_thematic_vowel("ɑ")  # All words end with /a/ as last vowel
    # .with_thematic_vowel(IPA::Utils.find_phoneme("a").not_nil!)  # Using IPA::Phoneme
    # ```
    #
    # ## Note
    # This creates words like "thranas", "kona", "tenask" where 'a' is always
    # the final vowel, regardless of other vowels or consonants that follow.
    def with_thematic_vowel(vowel : String | IPA::Phoneme)
      @thematic_vowel = case vowel
                       when String
                         vowel
                       when IPA::Phoneme
                         vowel.symbol
                       else
                         raise "Invalid vowel type"
                       end
      self
    end

    # Sets a starting sequence constraint forcing words to begin with specific phonemes.
    #
    # ## Parameters
    # - `sequence`: The romanized sequence that must start all generated words
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .starting_with_sequence("thra")  # All words start with "thra"
    # ```
    #
    # ## Note
    # This creates words like "thraesy", "thranor" where the exact sequence
    # is preserved at the beginning, then normal generation continues.
    def starting_with_sequence(sequence : String)
      @starts_with = sequence
      self
    end

    # Sets an ending sequence constraint forcing words to end with specific phonemes.
    #
    # ## Parameters
    # - `sequence`: The romanized sequence that must end all generated words
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .ending_with_sequence("ath")  # All words end with "ath"
    # ```
    #
    # ## Note
    # This creates words like "gorath", "menath" where the exact sequence
    # is preserved at the end, with normal generation before it.
    def ending_with_sequence(sequence : String)
      @ends_with = sequence
      self
    end

    # Sets the gemination probability for consonant doubling.
    #
    # ## Parameters
    # - `probability`: Probability (0.0-1.0) of consonant gemination
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_gemination_probability(0.1)  # 10% chance of consonant doubling
    # ```
    #
    # ## Note
    # Gemination creates words like "tenna", "korro", "silla" where consonants
    # are doubled to create emphasis or length. Common in many natural languages.
    def with_gemination_probability(probability : Float32)
      @gemination_probability = probability
      self
    end

    # Sets the vowel lengthening probability for vowel doubling.
    #
    # ## Parameters
    # - `probability`: Probability (0.0-1.0) of vowel lengthening
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_vowel_lengthening_probability(0.15)  # 15% chance of vowel lengthening
    # ```
    #
    # ## Note
    # Vowel lengthening creates words like "kaara", "niilon", "tuuro" where vowels
    # are doubled to create length or emphasis. Common in languages like Finnish.
    def with_vowel_lengthening_probability(probability : Float32)
      @vowel_lengthening_probability = probability
      self
    end

    # Enables gemination with maximum probability (100%).
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .enable_gemination  # 100% chance of consonant doubling
    # ```
    #
    # ## Note
    # Convenience method equivalent to `with_gemination_probability(1.0)`.
    def enable_gemination
      @gemination_probability = 1.0_f32
      self
    end

    # Disables gemination (0% probability).
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .disable_gemination  # No consonant doubling
    # ```
    #
    # ## Note
    # Convenience method equivalent to `with_gemination_probability(0.0)`.
    def disable_gemination
      @gemination_probability = 0.0_f32
      self
    end

    # Enables vowel lengthening with maximum probability (100%).
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .enable_vowel_lengthening  # 100% chance of vowel lengthening
    # ```
    #
    # ## Note
    # Convenience method equivalent to `with_vowel_lengthening_probability(1.0)`.
    def enable_vowel_lengthening
      @vowel_lengthening_probability = 1.0_f32
      self
    end

    # Disables vowel lengthening (0% probability).
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .disable_vowel_lengthening  # No vowel lengthening
    # ```
    #
    # ## Note
    # Convenience method equivalent to `with_vowel_lengthening_probability(0.0)`.
    def disable_vowel_lengthening
      @vowel_lengthening_probability = 0.0_f32
      self
    end

    # Sets the complexity cost for consonant clusters.
    #
    # ## Parameters
    # - `cost`: Cost per consonant cluster (default: 3.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_cluster_cost(5.0_f32)  # Make clusters more expensive
    # ```
    def with_cluster_cost(cost : Float32)
      @cluster_cost = cost
      self
    end

    # Sets the complexity cost for hiatus sequences.
    #
    # ## Parameters
    # - `cost`: Cost per hiatus sequence (default: 2.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_hiatus_cost(1.0_f32)  # Make hiatus cheaper
    # ```
    def with_hiatus_cost(cost : Float32)
      @hiatus_cost = cost
      self
    end

    # Sets the complexity cost for complex codas.
    #
    # ## Parameters
    # - `cost`: Cost per complex coda (default: 2.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_complex_coda_cost(4.0_f32)  # Make complex codas more expensive
    # ```
    def with_complex_coda_cost(cost : Float32)
      @complex_coda_cost = cost
      self
    end

    # Sets the complexity cost for gemination.
    #
    # ## Parameters
    # - `cost`: Cost per gemination (default: 3.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_gemination_cost(2.0_f32)  # Make gemination cheaper
    # ```
    def with_gemination_cost(cost : Float32)
      @gemination_cost = cost
      self
    end

    # Sets the complexity cost for vowel lengthening.
    #
    # ## Parameters
    # - `cost`: Cost per vowel lengthening (default: 1.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_vowel_lengthening_cost(0.5_f32)  # Make vowel lengthening very cheap
    # ```
    def with_vowel_lengthening_cost(cost : Float32)
      @vowel_lengthening_cost = cost
      self
    end

    # Sets all complexity costs at once.
    #
    # ## Parameters
    # - `cluster`: Cost per consonant cluster (default: 3.0)
    # - `hiatus`: Cost per hiatus sequence (default: 2.0)
    # - `coda`: Cost per complex coda (default: 2.0)
    # - `gemination`: Cost per gemination (default: 3.0)
    # - `vowel_lengthening`: Cost per vowel lengthening (default: 1.0)
    #
    # ## Returns
    # Self for method chaining
    #
    # ## Example
    # ```crystal
    # .with_complexity_costs(
    #   cluster: 4.0_f32,
    #   hiatus: 1.5_f32,
    #   gemination: 2.0_f32
    # )
    # ```
    def with_complexity_costs(cluster : Float32 = 3.0_f32, hiatus : Float32 = 2.0_f32, coda : Float32 = 2.0_f32, gemination : Float32 = 3.0_f32, vowel_lengthening : Float32 = 1.0_f32)
      @cluster_cost = cluster
      @hiatus_cost = hiatus
      @complex_coda_cost = coda
      @gemination_cost = gemination
      @vowel_lengthening_cost = vowel_lengthening
      self
    end

    # Builds the final Generator instance.
    #
    # ## Returns
    # Configured Generator ready for word generation
    #
    # ## Raises
    # Raises if required components (phonemes, syllable patterns, syllable count) are missing
    # Raises if syllable patterns contain undefined custom symbols
    def build : Generator
      # Validate that all custom symbols in patterns are defined
      validate_pattern_symbols
      
      # Validate thematic vowel if specified
      validate_thematic_vowel
      
      word_spec = WordSpec.new(
        syllable_count: @syllable_count.not_nil!,
        starting_type: @starting_type,
        syllable_templates: @syllable_templates.not_nil!,
        word_constraints: @constraints || [] of String,
        thematic_vowel: @thematic_vowel,
        starts_with: @starts_with,
        ends_with: @ends_with
      )

      Generator.new(
        phoneme_set: @phoneme_set.not_nil!,
        word_spec: word_spec,
        romanizer: @romanizer || RomanizationMap.new,
        mode: @mode || GenerationMode::Random,
        max_words: @max_words || 1000,
        complexity_budget: @complexity_budget,
        hiatus_escalation_factor: @hiatus_escalation_factor || 1.5_f32,
        vowel_harmony: @vowel_harmony,
        gemination_probability: @gemination_probability || 0.0_f32,
        vowel_lengthening_probability: @vowel_lengthening_probability || 0.0_f32,
        phoneme_transitions: @phoneme_transitions || Hash(String, Hash(String, Float32)).new,
        transition_weight_factor: @transition_weight_factor || 1.0_f32,
        positional_frequencies: @positional_frequencies || Hash(String, Hash(String, Float32)).new,
        gemination_patterns: @gemination_patterns || Hash(String, Float32).new,
        vowel_lengthening_patterns: @vowel_lengthening_patterns || Hash(String, Float32).new,
        cluster_cost: @cluster_cost || 3.0_f32,
        hiatus_cost: @hiatus_cost || 2.0_f32,
        complex_coda_cost: @complex_coda_cost || 2.0_f32,
        gemination_cost: @gemination_cost || 3.0_f32,
        vowel_lengthening_cost: @vowel_lengthening_cost || 1.0_f32
      )
    end

    # Validates that all symbols in syllable patterns have corresponding phoneme groups defined.
    #
    # ## Raises
    # Raises if any pattern contains an undefined custom symbol
    private def validate_pattern_symbols
      return unless @syllable_templates && @phoneme_set
      
      phoneme_set = @phoneme_set.not_nil!
      templates = @syllable_templates.not_nil!
      
      templates.each do |template|
        template.pattern.each_char do |symbol|
          # Skip standard symbols
          next if symbol == 'C' || symbol == 'V'
          
          # Check if custom symbol is defined
          unless phoneme_set.has_custom_group?(symbol)
            raise "Pattern symbol '#{symbol}' is not defined. Use with_custom_group('#{symbol}', [...]) to define it."
          end
        end
      end
    end

    private def validate_thematic_vowel
      return unless @thematic_vowel && @phoneme_set
      
      phoneme_set = @phoneme_set.not_nil!
      thematic_vowel = @thematic_vowel.not_nil!
      
      # Check if the thematic vowel matches any romanized vowel in the set
      # Use the romanization map to convert phonemes to romanized form, just like during word generation
      romanizer = @romanizer || RomanizationMap.new
      
      valid_romanized_vowels = phoneme_set.vowels.map { |vowel| romanizer.romanize([vowel.symbol]) }
      
      unless valid_romanized_vowels.includes?(thematic_vowel)
        raise ArgumentError.new("Thematic vowel '#{thematic_vowel}' is not in the vowel set")
      end
    end
  end
end