require "./word_analyzer"

module WordMage
  # Defines the generation mode for word creation.
  #
  # - **Random**: Generate words randomly using the phoneme and template rules
  # - **Sequential**: Generate all possible word combinations systematically
  # - **WeightedRandom**: Like Random but respects phoneme weights
  enum GenerationMode
    Random
    Sequential
    WeightedRandom
  end

  # Main word generation engine that combines all components.
  #
  # Generator is the central class that orchestrates word creation using
  # PhonemeSet, WordSpec, SyllableTemplates, and RomanizationMap. It supports
  # multiple generation modes and handles constraint validation.
  #
  # ## Example
  # ```crystal
  # generator = Generator.new(
  #   phoneme_set: phonemes,
  #   word_spec: word_spec,
  #   romanizer: romanizer,
  #   mode: GenerationMode::Random
  # )
  # word = generator.generate
  # batch = generator.generate_batch(10)
  # ```
  class Generator
    property phoneme_set : PhonemeSet
    property word_spec : WordSpec
    property romanizer : RomanizationMap
    property mode : GenerationMode
    property max_words : Int32
    property complexity_budget : Int32?
    property hiatus_escalation_factor : Float32 = 1.0
    property vowel_harmony : VowelHarmony?
    property gemination_probability : Float32 = 0.0
    property vowel_lengthening_probability : Float32 = 0.0

    @sequential_state : Hash(String, Int32)?

    # Creates a new Generator.
    #
    # ## Parameters
    # - `phoneme_set`: PhonemeSet containing available consonants and vowels
    # - `word_spec`: WordSpec defining generation requirements
    # - `romanizer`: RomanizationMap for converting phonemes to text
    # - `mode`: GenerationMode (Random, Sequential, or WeightedRandom)
    # - `max_words`: Maximum words for sequential mode (default: 1000)
    # - `complexity_budget`: Optional complexity budget for melodic control
    # - `hiatus_escalation_factor`: Multiplier for hiatus cost as more appear (default: 1.5)
    # - `vowel_harmony`: Optional vowel harmony rules
    # - `gemination_probability`: Probability (0.0-1.0) of consonant gemination (default: 0.0)
    # - `vowel_lengthening_probability`: Probability (0.0-1.0) of vowel lengthening (default: 0.0)
    def initialize(@phoneme_set : PhonemeSet, @word_spec : WordSpec, @romanizer : RomanizationMap, @mode : GenerationMode, @max_words : Int32 = 1000, @complexity_budget : Int32? = nil, @hiatus_escalation_factor : Float32 = 1.5_f32, @vowel_harmony : VowelHarmony? = nil, @gemination_probability : Float32 = 0.0_f32, @vowel_lengthening_probability : Float32 = 0.0_f32)
      @sequential_state = nil
    end

    # Generates a single word according to the current mode.
    #
    # ## Returns
    # A romanized word string
    #
    # ## Raises
    # Raises if sequential mode has no more words available
    def generate : String
      case @mode
      when .sequential?
        next_sequential || raise "No more sequential words available"
      else
        generate_random
      end
    end

    # Generates a word with a specific syllable count.
    #
    # ## Parameters
    # - `syllable_count`: Exact number of syllables to generate
    #
    # ## Returns
    # A romanized word string with the specified syllable count
    def generate(syllable_count : Int32) : String
      generate_random_with_syllable_count(syllable_count)
    end

    # Generates a word with syllable count from a range.
    #
    # ## Parameters  
    # - `min_syllables`: Minimum syllable count
    # - `max_syllables`: Maximum syllable count
    #
    # ## Returns
    # A romanized word string with syllables in the specified range
    def generate(min_syllables : Int32, max_syllables : Int32) : String
      syllable_count = Random.rand(min_syllables..max_syllables)
      generate_random_with_syllable_count(syllable_count)
    end

    # Generates a word with a specific starting type.
    #
    # ## Parameters
    # - `starting_type`: Either `:vowel` or `:consonant`
    #
    # ## Returns
    # A romanized word string starting with the specified phoneme type
    def generate(starting_type : Symbol) : String
      generate_with_starting_type(starting_type)
    end

    # Generates a word with both syllable count and starting type.
    #
    # ## Parameters
    # - `syllable_count`: Exact number of syllables
    # - `starting_type`: Either `:vowel` or `:consonant`
    #
    # ## Returns  
    # A romanized word string with specified syllables and starting type
    def generate(syllable_count : Int32, starting_type : Symbol) : String
      generate_with_syllable_count_and_starting_type(syllable_count, starting_type)
    end

    # Generates multiple words.
    #
    # ## Parameters
    # - `count`: Number of words to generate
    #
    # ## Returns
    # Array of romanized word strings
    def generate_batch(count : Int32) : Array(String)
      (1..count).map { generate }
    end

    # Gets the next word in sequential mode.
    #
    # ## Returns
    # Next word string, or `nil` if no more words available
    #
    # ## Note
    # Only works in Sequential mode. Call `reset_sequential` to start over.
    def next_sequential : String?
      init_sequential_state if @sequential_state.nil?
      
      state = @sequential_state.not_nil!
      return nil if state["current_count"] >= @max_words

      word = generate_sequential_word(state["current_combination"])
      state["current_combination"] += 1
      state["current_count"] += 1

      word
    end

    # Resets sequential generation to start from the beginning.
    #
    # ## Note
    # Only affects Sequential mode. Has no effect in other modes.
    def reset_sequential
      @sequential_state = nil
    end

    private def generate_random : String
      syllable_count = @word_spec.generate_syllable_count
      generate_random_with_syllable_count(syllable_count)
    end

    private def generate_random_with_syllable_count(syllable_count : Int32) : String
      generate_with_syllable_count_and_starting_type(syllable_count, @word_spec.starting_type)
    end

    private def generate_with_starting_type(starting_type : Symbol) : String
      syllable_count = @word_spec.generate_syllable_count
      generate_with_syllable_count_and_starting_type(syllable_count, starting_type)
    end

    private def generate_with_syllable_count_and_starting_type(syllable_count : Int32, starting_type : Symbol?) : String
      # Adjust syllable count for sequence constraints to account for phonetic integration
      adjusted_syllable_count = syllable_count
      if (@word_spec.starts_with && !@word_spec.starts_with.not_nil!.empty?) || (@word_spec.ends_with && !@word_spec.ends_with.not_nil!.empty?)
        # Reduce syllable count by 1 if we have sequence constraints to account for phonetic integration
        adjusted_syllable_count = [1, syllable_count - 1].max
        # puts "DEBUG: Adjusting syllable count from #{syllable_count} to #{adjusted_syllable_count} for sequence constraints"
      end
      
      # Use complexity budget if available
      if budget = @complexity_budget
        generate_with_complexity_budget(adjusted_syllable_count, starting_type, budget, syllable_count)
      else
        generate_without_complexity_budget(adjusted_syllable_count, starting_type, syllable_count)
      end
    end

    # Generates words with complexity budget tracking
    private def generate_with_complexity_budget(syllable_count : Int32, starting_type : Symbol?, initial_budget : Int32, original_syllable_count : Int32 = syllable_count) : String
      syllables = [] of Array(String)
      used_vowels = Set(String).new
      vowel_sequence = [] of String  # Track vowel sequence for harmony
      remaining_budget = initial_budget.to_f32
      hiatus_count = 0
      
      # Handle starts_with and ends_with constraints
      prefix_phonemes = @word_spec.get_required_prefix(@romanizer)
      suffix_phonemes = @word_spec.get_required_suffix(@romanizer)
      
      # Track prefix vowels and cost
      if !prefix_phonemes.empty?
        prefix_phonemes.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
        remaining_budget = [0.0_f32, remaining_budget - 1.0_f32].max
      end
      
      # Track suffix vowels and cost
      if !suffix_phonemes.empty?
        suffix_phonemes.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
        remaining_budget = [0.0_f32, remaining_budget - 1.0_f32].max
      end
      
      # Generate the full number of syllables as requested
      # Prefixes and suffixes will be attached to first/last syllables
      (0...syllable_count).each do |i|
        position = case i
                   when 0 then :initial
                   when syllable_count - 1 then :final
                   else :medial
                   end

        # Select template and generate syllable with budget constraints
        template = if remaining_budget > 0
                     @word_spec.select_template(position)
                   else
                     # Budget exhausted - use simple CV pattern only
                     select_simple_template(position)
                   end

        syllable = generate_syllable_with_budget_and_harmony(template, position, used_vowels, vowel_sequence, remaining_budget.to_i)
        
        # Attach prefix to first syllable, but ensure phonological validity
        if i == 0 && !prefix_phonemes.empty?
          # Check if prefix ends with consonant and syllable starts with consonant
          prefix_ends_with_consonant = !@phoneme_set.is_vowel?(prefix_phonemes.last)
          syllable_starts_with_consonant = !syllable.empty? && !@phoneme_set.is_vowel?(syllable.first)
          
          if prefix_ends_with_consonant && syllable_starts_with_consonant
            # Invalid: consonant cluster would be too long (e.g., "thr" + "t" = "thrt")
            # Generate a vowel-initial syllable instead
            template = @word_spec.select_template(position)
            syllable = generate_vowel_initial_syllable(template, position)
          end
          
          syllable = prefix_phonemes + syllable
        end
        
        # Attach suffix to last syllable
        if i == syllable_count - 1 && !suffix_phonemes.empty?
          syllable = syllable + suffix_phonemes
        end
        
        syllables << syllable
        
        # Calculate complexity cost with hiatus escalation
        cost = calculate_complexity_cost_with_escalation(syllable, template, hiatus_count)
        remaining_budget = [0.0_f32, remaining_budget - cost].max
        
        # Track hiatus sequences for escalation
        hiatus_count += count_vowel_sequences(syllable)
        
        # Track vowels used and vowel sequence
        syllable.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
      end
      
      phonemes = syllables.flatten

      # Apply gemination if enabled
      if @gemination_probability > 0.0
        phonemes = apply_gemination(phonemes)
      end

      # Apply vowel lengthening if enabled
      if @vowel_lengthening_probability > 0.0
        phonemes = apply_vowel_lengthening(phonemes)
      end

      # Check word-level constraints, starting type, and phonological issues
      romanized_word = @romanizer.romanize(phonemes)
      
      # For sequence constraints, validate actual syllable count
      syllable_count_valid = true
      if @word_spec.starts_with || @word_spec.ends_with
        actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
        syllable_count_valid = actual_syllable_count >= @word_spec.syllable_count.min && actual_syllable_count <= @word_spec.syllable_count.max
      else
        actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
        syllable_count_valid = actual_syllable_count == original_syllable_count
      end
      
      if @word_spec.validate_word(phonemes, @romanizer) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && !has_vowel_gemination?(phonemes) && syllable_count_valid
        romanized_word
      else
        generate_with_complexity_budget_with_retries(syllable_count, starting_type, initial_budget, 0, original_syllable_count) # Retry with limit
      end
    end

    # Generate with complexity budget and retry limit
    private def generate_with_complexity_budget_with_retries(syllable_count : Int32, starting_type : Symbol?, initial_budget : Int32, retries : Int32, original_syllable_count : Int32 = syllable_count) : String
      return generate_fallback_word if retries >= 100  # Fallback after too many retries
      
      syllables = [] of Array(String)
      used_vowels = Set(String).new
      vowel_sequence = [] of String  # Track vowel sequence for harmony
      remaining_budget = initial_budget.to_f32
      hiatus_count = 0
      
      # Handle starts_with and ends_with constraints by preparing prefix and suffix
      prefix_phonemes = @word_spec.get_required_prefix(@romanizer)
      suffix_phonemes = @word_spec.get_required_suffix(@romanizer)
      if !prefix_phonemes.empty?
        # Track prefix vowels and consonants for harmony
        prefix_phonemes.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
        
        # Calculate cost of prefix (fixed cost of 1 to account for the constraint)
        remaining_budget = [0.0_f32, remaining_budget - 1.0_f32].max
      end
      
      if !suffix_phonemes.empty?
        # Track suffix vowels and consonants for harmony
        suffix_phonemes.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
        
        # Calculate cost of suffix (fixed cost of 1 to account for the constraint)
        remaining_budget = [0.0_f32, remaining_budget - 1.0_f32].max
      end
      
      (0...syllable_count).each do |i|
        position = case i
                   when 0 then :initial
                   when syllable_count - 1 then :final
                   else :medial
                   end

        # Select template and generate syllable with budget constraints
        template = if remaining_budget > 0
                     @word_spec.select_template(position)
                   else
                     # Budget exhausted - use simple CV pattern only
                     select_simple_template(position)
                   end

        syllable = generate_syllable_with_budget_and_harmony(template, position, used_vowels, vowel_sequence, remaining_budget.to_i)
        
        # For the first syllable, prepend the prefix if it exists
        if i == 0 && !prefix_phonemes.empty?
          syllable = prefix_phonemes + syllable
        end
        
        # For the last syllable, append the suffix if it exists
        if i == syllable_count - 1 && !suffix_phonemes.empty?
          syllable = syllable + suffix_phonemes
        end
        
        syllables << syllable
        
        # Calculate complexity cost with hiatus escalation
        cost = calculate_complexity_cost_with_escalation(syllable, template, hiatus_count)
        remaining_budget = [0.0_f32, remaining_budget - cost].max
        
        # Track hiatus sequences for escalation
        hiatus_count += count_vowel_sequences(syllable)
        
        # Track vowels used and vowel sequence
        syllable.each do |phoneme|
          if @phoneme_set.is_vowel?(phoneme)
            used_vowels.add(phoneme)
            vowel_sequence << phoneme
          end
        end
      end
      
      phonemes = syllables.flatten

      # Apply gemination if enabled
      if @gemination_probability > 0.0
        phonemes = apply_gemination(phonemes)
      end

      # Apply vowel lengthening if enabled
      if @vowel_lengthening_probability > 0.0
        phonemes = apply_vowel_lengthening(phonemes)
      end

      # Check word-level constraints, starting type, and phonological issues
      # Also verify the actual syllable count matches the target
      romanized_word = @romanizer.romanize(phonemes)
      actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
      
      # For sequence constraints, validate actual syllable count is within the original range
      syllable_count_valid = true
      if @word_spec.starts_with || @word_spec.ends_with
        syllable_count_valid = actual_syllable_count >= @word_spec.syllable_count.min && actual_syllable_count <= @word_spec.syllable_count.max
      else
        # For non-sequence constraints, use original permissive validation
        syllable_count_valid = true
      end
      
      if @word_spec.validate_word(phonemes, @romanizer) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && !has_vowel_gemination?(phonemes) && syllable_count_valid
        romanized_word
      else
        generate_with_complexity_budget_with_retries(syllable_count, starting_type, initial_budget, retries + 1, original_syllable_count)
      end
    end

    # Original generation without complexity budget
    private def generate_without_complexity_budget(syllable_count : Int32, starting_type : Symbol?, original_syllable_count : Int32 = syllable_count) : String
      syllables = [] of Array(String)

      # Handle starts_with and ends_with constraints
      prefix_phonemes = @word_spec.get_required_prefix(@romanizer)
      suffix_phonemes = @word_spec.get_required_suffix(@romanizer)
      
      # Generate the full number of syllables as requested
      # Prefixes and suffixes will be attached to first/last syllables
      (0...syllable_count).each do |i|
        position = case i
                   when 0 then :initial
                   when syllable_count - 1 then :final
                   else :medial
                   end

        template = @word_spec.select_template(position)
        syllable = template.generate(@phoneme_set, position, @romanizer)
        
        # Attach prefix to first syllable, but ensure phonological validity
        if i == 0 && !prefix_phonemes.empty?
          # Check if prefix ends with consonant and syllable starts with consonant
          prefix_ends_with_consonant = !@phoneme_set.is_vowel?(prefix_phonemes.last)
          syllable_starts_with_consonant = !syllable.empty? && !@phoneme_set.is_vowel?(syllable.first)
          
          if prefix_ends_with_consonant && syllable_starts_with_consonant
            # Invalid: consonant cluster would be too long (e.g., "thr" + "t" = "thrt")
            # Generate a vowel-initial syllable instead
            template = @word_spec.select_template(position)
            syllable = generate_vowel_initial_syllable(template, position)
          end
          
          syllable = prefix_phonemes + syllable
        end
        
        # Attach suffix to last syllable
        if i == syllable_count - 1 && !suffix_phonemes.empty?
          syllable = syllable + suffix_phonemes
        end
        
        syllables << syllable
      end

      phonemes = syllables.flatten

      # Check word-level constraints, starting type, and phonological issues
      # Also verify the actual syllable count matches the target
      romanized_word = @romanizer.romanize(phonemes)
      actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
      
      # For sequence constraints, validate actual syllable count is within the original range
      syllable_count_valid = true
      if @word_spec.starts_with || @word_spec.ends_with
        syllable_count_valid = actual_syllable_count >= @word_spec.syllable_count.min && actual_syllable_count <= @word_spec.syllable_count.max
      else
        # For non-sequence constraints, use original permissive validation
        syllable_count_valid = true
      end
      
      if @word_spec.validate_word(phonemes, @romanizer) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && syllable_count_valid
        romanized_word
      else
        # Add retry limit to prevent infinite recursion
        generate_without_complexity_budget_with_retries(syllable_count, starting_type, 0, original_syllable_count) 
      end
    end

    # Generate with retry limit to prevent infinite recursion
    private def generate_without_complexity_budget_with_retries(syllable_count : Int32, starting_type : Symbol?, retries : Int32, original_syllable_count : Int32 = syllable_count) : String
      return generate_fallback_word if retries >= 100  # Fallback after too many retries
      
      syllables = [] of Array(String)

      # Handle starts_with and ends_with constraints
      prefix_phonemes = @word_spec.get_required_prefix(@romanizer)
      suffix_phonemes = @word_spec.get_required_suffix(@romanizer)
      
      # Generate the full number of syllables as requested
      # Prefixes and suffixes will be attached to first/last syllables
      (0...syllable_count).each do |i|
        position = case i
                   when 0 then :initial
                   when syllable_count - 1 then :final
                   else :medial
                   end

        template = @word_spec.select_template(position)
        syllable = template.generate(@phoneme_set, position, @romanizer)
        
        # Attach prefix to first syllable, but ensure phonological validity
        if i == 0 && !prefix_phonemes.empty?
          # Check if prefix ends with consonant and syllable starts with consonant
          prefix_ends_with_consonant = !@phoneme_set.is_vowel?(prefix_phonemes.last)
          syllable_starts_with_consonant = !syllable.empty? && !@phoneme_set.is_vowel?(syllable.first)
          
          if prefix_ends_with_consonant && syllable_starts_with_consonant
            # Invalid: consonant cluster would be too long (e.g., "thr" + "t" = "thrt")
            # Generate a vowel-initial syllable instead
            template = @word_spec.select_template(position)
            syllable = generate_vowel_initial_syllable(template, position)
          end
          
          syllable = prefix_phonemes + syllable
        end
        
        # Attach suffix to last syllable
        if i == syllable_count - 1 && !suffix_phonemes.empty?
          syllable = syllable + suffix_phonemes
        end
        
        syllables << syllable
      end

      phonemes = syllables.flatten

      # Apply gemination if enabled
      if @gemination_probability > 0.0
        phonemes = apply_gemination(phonemes)
      end

      # Apply vowel lengthening if enabled
      if @vowel_lengthening_probability > 0.0
        phonemes = apply_vowel_lengthening(phonemes)
      end

      # Check word-level constraints, starting type, and phonological issues
      romanized_word = @romanizer.romanize(phonemes)
      actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
      
      # For sequence constraints, validate actual syllable count is within the original range
      syllable_count_valid = true
      if @word_spec.starts_with || @word_spec.ends_with
        syllable_count_valid = actual_syllable_count >= @word_spec.syllable_count.min && actual_syllable_count <= @word_spec.syllable_count.max
      else
        # For non-sequence constraints, use original permissive validation
        syllable_count_valid = true
      end
      
      if @word_spec.validate_word(phonemes, @romanizer) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && syllable_count_valid
        romanized_word
      else
        generate_without_complexity_budget_with_retries(syllable_count, starting_type, retries + 1, original_syllable_count)
      end
    end

    # Fallback word generation when constraints can't be satisfied
    private def generate_fallback_word : String
      # Generate a simple CV word as fallback
      consonants = @phoneme_set.get_consonants
      vowels = @phoneme_set.get_vowels
      
      return "ka" if consonants.empty? || vowels.empty?
      
      phonemes = [consonants.sample, vowels.sample]
      @romanizer.romanize(phonemes)
    end

    # Applies gemination (consonant doubling) to phonemes based on probability.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes to potentially geminate
    #
    # ## Returns
    # Array of phonemes with potential gemination applied
    private def apply_gemination(phonemes : Array(String)) : Array(String)
      return phonemes if phonemes.size < 2
      
      result = [] of String
      i = 0
      
      while i < phonemes.size
        current_phoneme = phonemes[i]
        result << current_phoneme
        
        # Only geminate consonants that aren't at the end and aren't already doubled
        if i < phonemes.size - 1 && 
           !@phoneme_set.is_vowel?(current_phoneme) && 
           Random.rand < @gemination_probability &&
           (i == 0 || phonemes[i-1] != current_phoneme) &&  # Not already doubled
           phonemes[i+1] != current_phoneme  # Next isn't same (avoid triple)
          
          # Add the geminated consonant
          result << current_phoneme
        end
        
        i += 1
      end
      
      result
    end

    # Counts the number of syllables in a phoneme sequence using the same logic as WordAnalyzer
    private def count_syllables_in_phonemes(phonemes : Array(String)) : Int32
      return 0 if phonemes.empty?
      
      # Use the same syllable detection logic as WordAnalyzer to ensure consistency
      analyzer = WordAnalyzer.new(@romanizer)
      syllables = analyzer.detect_syllables(phonemes)
      syllables.size
    end
    
    # Generates a vowel-initial syllable to avoid consonant cluster problems
    private def generate_vowel_initial_syllable(template : SyllableTemplate, position : Symbol) : Array(String)
      # Force the syllable to start with a vowel
      vowel = @phoneme_set.sample_phoneme(:vowel, position)
      
      # Generate the rest of the syllable pattern after the vowel
      remaining_pattern = template.pattern.sub(/^C*/, "")  # Remove leading consonants
      syllable = [vowel]
      
      remaining_pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << @phoneme_set.sample_phoneme(:consonant, position)
        when 'V'
          syllable << @phoneme_set.sample_phoneme(:vowel, position)
        else
          # Handle custom symbols
          if @phoneme_set.has_custom_group?(symbol)
            syllable << @phoneme_set.sample_phoneme(symbol, position)
          end
        end
      end
      
      syllable
    end

    # Applies vowel lengthening (vowel doubling) to phonemes based on probability.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes to potentially lengthen
    #
    # ## Returns
    # Array of phonemes with potential vowel lengthening applied
    private def apply_vowel_lengthening(phonemes : Array(String)) : Array(String)
      return phonemes if phonemes.size < 1
      
      result = [] of String
      i = 0
      
      while i < phonemes.size
        current_phoneme = phonemes[i]
        result << current_phoneme
        
        # Only lengthen vowels that aren't at the end and aren't already doubled
        if i < phonemes.size - 1 && 
           @phoneme_set.is_vowel?(current_phoneme) && 
           Random.rand < @vowel_lengthening_probability &&
           (i == 0 || phonemes[i-1] != current_phoneme) &&  # Not already doubled
           phonemes[i+1] != current_phoneme  # Next isn't same (avoid triple)
          
          # Add the lengthened vowel
          result << current_phoneme
        end
        
        i += 1
      end
      
      result
    end

    # Generates syllable respecting budget constraints
    private def generate_syllable_with_budget(template : SyllableTemplate, position : Symbol, used_vowels : Set(String), remaining_budget : Int32) : Array(String)
      if remaining_budget <= 2
        # Low budget - use vowel harmony and simple patterns
        generate_melodic_syllable(template, position, used_vowels)
      else
        # Normal generation with budget
        template.generate(@phoneme_set, position, @romanizer)
      end
    end

    # Generates syllable with both budget and vowel harmony constraints
    private def generate_syllable_with_budget_and_harmony(template : SyllableTemplate, position : Symbol, used_vowels : Set(String), vowel_sequence : Array(String), remaining_budget : Int32) : Array(String)
      if remaining_budget <= 2
        # Low budget - use vowel harmony and simple patterns
        generate_melodic_syllable_with_harmony(template, position, used_vowels, vowel_sequence)
      else
        # Normal generation with vowel harmony
        generate_syllable_with_harmony(template, position, vowel_sequence)
      end
    end

    # Generates syllable with vowel harmony applied
    private def generate_syllable_with_harmony(template : SyllableTemplate, position : Symbol, vowel_sequence : Array(String)) : Array(String)
      return template.generate(@phoneme_set, position, @romanizer) unless @vowel_harmony && @vowel_harmony.not_nil!.active?
      
      # For complex patterns with clusters, use normal generation then apply harmony to vowels only
      if template.pattern.includes?("CC") || template.allowed_clusters || template.allowed_coda_clusters
        return apply_harmony_to_existing_syllable(template.generate(@phoneme_set, position, @romanizer), vowel_sequence, position)
      end
      
      # For simple patterns, generate with harmony
      syllable = [] of String
      
      template.pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << @phoneme_set.sample_phoneme(:consonant, position)
        when 'V'
          if template.allows_hiatus? && Random.rand < template.hiatus_probability
            # Generate hiatus with harmony and gemination check
            first_vowel = select_vowel_with_harmony(vowel_sequence, position)
            syllable << first_vowel
            
            # Second vowel should follow harmony from first AND be different
            available_vowels = @phoneme_set.get_vowels(position).reject { |v| v == first_vowel }
            if available_vowels.empty?
              # Fallback if no different vowels available
              available_vowels = @phoneme_set.get_vowels(position)
            end
            second_vowel = @vowel_harmony.not_nil!.select_vowel(first_vowel, available_vowels)
            syllable << second_vowel
          else
            # Single vowel with harmony
            vowel = select_vowel_with_harmony(vowel_sequence, position)
            syllable << vowel
          end
        else
          # Handle custom symbols
          if @phoneme_set.has_custom_group?(symbol)
            if template.allows_hiatus? && @phoneme_set.is_vowel_like_group?(symbol) && Random.rand < template.hiatus_probability
              # Generate hiatus for vowel-like custom groups with harmony
              first_phoneme = select_custom_phoneme_with_harmony(symbol, vowel_sequence, position)
              syllable << first_phoneme
              
              # Second phoneme should be different
              available_phonemes = @phoneme_set.get_custom_group(symbol, position).reject { |p| p == first_phoneme }
              if available_phonemes.empty?
                available_phonemes = @phoneme_set.get_custom_group(symbol, position)
              end
              
              # Apply harmony if the custom group is vowel-like
              second_phoneme = if @vowel_harmony && @vowel_harmony.not_nil!.active?
                                 @vowel_harmony.not_nil!.select_vowel(first_phoneme, available_phonemes)
                               else
                                 available_phonemes.sample
                               end
              syllable << second_phoneme
            else
              # Single phoneme from custom group
              phoneme = select_custom_phoneme_with_harmony(symbol, vowel_sequence, position)
              syllable << phoneme
            end
          else
            raise "Unknown pattern symbol '#{symbol}'"
          end
        end
      end
      
      # Validate and retry if needed
      if template.validate(syllable) && !has_vowel_gemination_in_syllable?(syllable)
        syllable
      else
        template.generate(@phoneme_set, position, @romanizer)  # Fallback to normal generation
      end
    end

    # Applies harmony to an already-generated syllable (for complex patterns)
    private def apply_harmony_to_existing_syllable(syllable : Array(String), vowel_sequence : Array(String), position : Symbol) : Array(String)
      return syllable unless @vowel_harmony && @vowel_harmony.not_nil!.active?
      
      harmony_syllable = [] of String
      
      syllable.each do |phoneme|
        if @phoneme_set.is_vowel?(phoneme)
          # Replace vowel with harmony-compatible one
          harmony_vowel = select_vowel_with_harmony(vowel_sequence, position)
          harmony_syllable << harmony_vowel
        else
          # Keep consonants as-is
          harmony_syllable << phoneme
        end
      end
      
      # Check for vowel gemination in the result
      if has_vowel_gemination_in_syllable?(harmony_syllable)
        return syllable  # Return original if harmony creates gemination
      end
      
      harmony_syllable
    end

    # Checks for vowel gemination within a single syllable
    private def has_vowel_gemination_in_syllable?(syllable : Array(String)) : Bool
      return false if syllable.size < 2
      
      (0...syllable.size-1).each do |i|
        current = syllable[i]
        next_phoneme = syllable[i+1]
        
        if @phoneme_set.is_vowel?(current) && current == next_phoneme
          return true
        end
      end
      
      false
    end

    # Generates melodic syllable with vowel harmony
    private def generate_melodic_syllable_with_harmony(template : SyllableTemplate, position : Symbol, used_vowels : Set(String), vowel_sequence : Array(String)) : Array(String)
      syllable = [] of String
      
      # Use simpler pattern - convert complex patterns to basic CV
      simplified_pattern = case template.pattern
                          when /^C+V+C*$/ then "CV"  # Any CCV+ becomes CV
                          when /^V+C*$/ then "V"     # Any VCC+ becomes V
                          else "CV"                  # Default fallback
                          end
      
      simplified_pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << @phoneme_set.sample_phoneme(:consonant, position)
        when 'V'
          # Use harmony first, then fall back to vowel reuse
          vowel = if @vowel_harmony && @vowel_harmony.not_nil!.active? && !vowel_sequence.empty?
                    select_vowel_with_harmony(vowel_sequence, position)
                  elsif !used_vowels.empty? && Random.rand < 0.6
                    # Avoid same vowel as the last phoneme if possible
                    available_vowels = used_vowels.to_a
                    if !syllable.empty? && @phoneme_set.is_vowel?(syllable.last)
                      available_vowels = available_vowels.reject { |v| v == syllable.last }
                      available_vowels = used_vowels.to_a if available_vowels.empty?
                    end
                    available_vowels.sample
                  else
                    @phoneme_set.sample_phoneme(:vowel, position)
                  end
          
          syllable << vowel
        else
          # Handle custom symbols
          if @phoneme_set.has_custom_group?(symbol)
            if @phoneme_set.is_vowel_like_group?(symbol)
              # Use similar logic as vowels for vowel-like custom groups
              phoneme = if @vowel_harmony && @vowel_harmony.not_nil!.active? && !vowel_sequence.empty?
                          select_custom_phoneme_with_harmony(symbol, vowel_sequence, position)
                        elsif !used_vowels.empty? && Random.rand < 0.6
                          # Reuse from the custom group if vowel-like
                          custom_phonemes = @phoneme_set.get_custom_group(symbol, position)
                          available_custom = custom_phonemes.select { |p| used_vowels.includes?(p) }
                          if available_custom.empty?
                            custom_phonemes.sample
                          else
                            available_custom.sample
                          end
                        else
                          @phoneme_set.sample_phoneme(symbol, position)
                        end
              syllable << phoneme
            else
              # Consonant-like custom groups
              syllable << @phoneme_set.sample_phoneme(symbol, position)
            end
          else
            raise "Unknown pattern symbol '#{symbol}'"
          end
        end
      end
      
      syllable
    end

    # Selects a vowel using vowel harmony rules
    private def select_vowel_with_harmony(vowel_sequence : Array(String), position : Symbol) : String
      available_vowels = @phoneme_set.get_vowels(position)
      
      return available_vowels.sample if vowel_sequence.empty? || !@vowel_harmony || !@vowel_harmony.not_nil!.active?
      
      # Use the last vowel in sequence to determine harmony
      last_vowel = vowel_sequence.last
      @vowel_harmony.not_nil!.select_vowel(last_vowel, available_vowels)
    end

    # Selects a phoneme from a custom group using vowel harmony rules (if vowel-like)
    private def select_custom_phoneme_with_harmony(symbol : Char, vowel_sequence : Array(String), position : Symbol) : String
      available_phonemes = @phoneme_set.get_custom_group(symbol, position)
      
      # If not vowel-like or no harmony active, just sample randomly
      return available_phonemes.sample unless @phoneme_set.is_vowel_like_group?(symbol) && @vowel_harmony && @vowel_harmony.not_nil!.active? && !vowel_sequence.empty?
      
      # Use the last vowel in sequence to determine harmony for vowel-like custom groups
      last_vowel = vowel_sequence.last
      @vowel_harmony.not_nil!.select_vowel(last_vowel, available_phonemes)
    end

    # Generates simple, melodic syllables when budget is low
    private def generate_melodic_syllable(template : SyllableTemplate, position : Symbol, used_vowels : Set(String)) : Array(String)
      syllable = [] of String
      
      # Use simpler pattern - convert complex patterns to basic CV
      # Fix: More careful pattern simplification
      simplified_pattern = case template.pattern
                          when /^C+V+C*$/ then "CV"  # Any CCV+ becomes CV
                          when /^V+C*$/ then "V"     # Any VCC+ becomes V
                          else "CV"                  # Default fallback
                          end
      
      simplified_pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << @phoneme_set.sample_phoneme(:consonant, position)
        when 'V'
          # Reuse existing vowels for harmony, but avoid recent duplicates
          if !used_vowels.empty? && Random.rand < 0.6
            # Avoid same vowel as the last phoneme if possible
            available_vowels = used_vowels.to_a
            if !syllable.empty? && @phoneme_set.is_vowel?(syllable.last)
              available_vowels = available_vowels.reject { |v| v == syllable.last }
              available_vowels = used_vowels.to_a if available_vowels.empty?
            end
            syllable << available_vowels.sample
          else
            syllable << @phoneme_set.sample_phoneme(:vowel, position)
          end
        else
          # Handle custom symbols
          if @phoneme_set.has_custom_group?(symbol)
            if @phoneme_set.is_vowel_like_group?(symbol) && !used_vowels.empty? && Random.rand < 0.6
              # Reuse existing vowels for vowel-like custom groups
              custom_phonemes = @phoneme_set.get_custom_group(symbol, position)
              available_custom = custom_phonemes.select { |p| used_vowels.includes?(p) }
              if available_custom.empty?
                syllable << @phoneme_set.sample_phoneme(symbol, position)
              else
                # Avoid same phoneme as the last phoneme if possible
                if !syllable.empty? && custom_phonemes.includes?(syllable.last)
                  available_custom = available_custom.reject { |p| p == syllable.last }
                  available_custom = custom_phonemes.select { |p| used_vowels.includes?(p) } if available_custom.empty?
                end
                syllable << available_custom.sample
              end
            else
              syllable << @phoneme_set.sample_phoneme(symbol, position)
            end
          else
            raise "Unknown pattern symbol '#{symbol}'"
          end
        end
      end
      
      syllable
    end

    # Calculates complexity cost of a syllable
    private def calculate_complexity_cost(syllable : Array(String), template : SyllableTemplate) : Int32
      cost = 0
      
      # Count clusters (adjacent consonants)
      consonant_clusters = count_consonant_clusters(syllable)
      cost += consonant_clusters * 3  # 3 points per cluster
      
      # Count hiatus (adjacent vowels)
      vowel_sequences = count_vowel_sequences(syllable)
      cost += vowel_sequences * 2  # 2 points per hiatus
      
      # Complex codas (CC at end)
      if template.pattern.ends_with?("CC")
        cost += 2
      end
      
      cost
    end

    # Calculates complexity cost with hiatus escalation factor
    private def calculate_complexity_cost_with_escalation(syllable : Array(String), template : SyllableTemplate, previous_hiatus_count : Int32) : Float32
      cost = 0.0_f32
      
      # Count clusters (adjacent consonants) - normal cost
      consonant_clusters = count_consonant_clusters(syllable)
      cost += consonant_clusters * 3.0_f32  # 3 points per cluster
      
      # Count hiatus (adjacent vowels) - escalating cost
      vowel_sequences = count_vowel_sequences(syllable)
      if vowel_sequences > 0
        # Each hiatus costs more based on how many we've already used
        # 1st hiatus: 2 points, 2nd: 3 points, 3rd: 4.5 points, etc.
        escalation_multiplier = @hiatus_escalation_factor ** previous_hiatus_count
        cost += vowel_sequences * 2.0_f32 * escalation_multiplier
      end
      
      # Complex codas (CC at end)
      if template.pattern.ends_with?("CC")
        cost += 2.0_f32
      end
      
      cost
    end

    # Counts consonant clusters in syllable
    private def count_consonant_clusters(syllable : Array(String)) : Int32
      return 0 if syllable.size < 2
      
      clusters = 0
      (0...syllable.size-1).each do |i|
        if !@phoneme_set.is_vowel?(syllable[i]) && !@phoneme_set.is_vowel?(syllable[i+1])
          clusters += 1
        end
      end
      clusters
    end

    # Counts vowel sequences (hiatus) in syllable
    private def count_vowel_sequences(syllable : Array(String)) : Int32
      return 0 if syllable.size < 2
      
      sequences = 0
      (0...syllable.size-1).each do |i|
        if @phoneme_set.is_vowel?(syllable[i]) && @phoneme_set.is_vowel?(syllable[i+1])
          sequences += 1
        end
      end
      sequences
    end

    # Selects simple template when budget is exhausted
    private def select_simple_template(position : Symbol) : SyllableTemplate
      # Return a simple CV template
      simple_template = @word_spec.syllable_templates.find { |t| t.pattern == "CV" }
      simple_template || @word_spec.syllable_templates.first
    end

    # Checks if there's gemination or problematic vowel sequences across syllable boundaries
    private def has_syllable_boundary_gemination?(syllables : Array(Array(String))) : Bool
      return false if syllables.size < 2

      # Check each syllable boundary
      (0...syllables.size-1).each do |i|
        current_syllable = syllables[i]
        next_syllable = syllables[i+1]
        
        next if current_syllable.empty? || next_syllable.empty?
        
        # Check if last phoneme of current syllable equals first phoneme of next syllable
        if current_syllable.last == next_syllable.first
          return true
        end
        
        # Check for excessive vowel sequences across boundary
        if has_excessive_vowel_sequence?(current_syllable, next_syllable)
          return true
        end
      end

      false
    end

    # Checks if joining two syllables would create 3+ consecutive vowels
    private def has_excessive_vowel_sequence?(current_syllable : Array(String), next_syllable : Array(String)) : Bool
      # Look at the end of current syllable and start of next syllable
      # Check up to 2 phonemes from each syllable to catch sequences like "ua" + "o" = "uao"
      
      current_end = current_syllable.last(2)  # Last 1-2 phonemes
      next_start = next_syllable.first(2)     # First 1-2 phonemes
      
      # Combine them and check for 3+ consecutive vowels
      boundary_sequence = current_end + next_start
      
      vowel_count = 0
      max_consecutive_vowels = 0
      
      boundary_sequence.each do |phoneme|
        if @phoneme_set.is_vowel?(phoneme)
          vowel_count += 1
          max_consecutive_vowels = [max_consecutive_vowels, vowel_count].max
        else
          vowel_count = 0
        end
      end
      
      # Reject if we have 3+ consecutive vowels
      max_consecutive_vowels >= 3
    end

    # Checks if the entire word has 3+ consecutive vowels anywhere
    private def has_excessive_vowel_sequences?(phonemes : Array(String)) : Bool
      vowel_count = 0
      
      phonemes.each do |phoneme|
        if @phoneme_set.is_vowel?(phoneme)
          vowel_count += 1
          return true if vowel_count >= 3  # Found 3+ consecutive vowels
        else
          vowel_count = 0
        end
      end
      
      false
    end

    # Checks if the word has vowel gemination (identical adjacent vowels)
    private def has_vowel_gemination?(phonemes : Array(String)) : Bool
      return false if phonemes.size < 2
      
      (0...phonemes.size-1).each do |i|
        current = phonemes[i]
        next_phoneme = phonemes[i+1]
        
        # Check for identical adjacent vowels
        if @phoneme_set.is_vowel?(current) && current == next_phoneme
          return true
        end
      end
      
      false
    end

    private def matches_starting_type?(phonemes : Array(String)) : Bool
      matches_starting_type_override?(phonemes, @word_spec.starting_type)
    end

    private def matches_starting_type_override?(phonemes : Array(String), starting_type : Symbol?) : Bool
      return true unless starting_type

      first_phoneme = phonemes.first?
      return false unless first_phoneme

      case starting_type
      when :vowel then @phoneme_set.is_vowel?(first_phoneme)
      when :consonant then !@phoneme_set.is_vowel?(first_phoneme)
      else true
      end
    end

    private def init_sequential_state
      @sequential_state = {
        "current_combination" => 0,
        "current_count" => 0
      }
    end

    private def generate_sequential_word(combination_index : Int32) : String
      # For simplicity, generate combinations of single CV syllables
      consonants = @phoneme_set.get_consonants
      vowels = @phoneme_set.get_vowels
      
      return "" if consonants.empty? || vowels.empty?

      syllable_count = @word_spec.syllable_count.min
      
      # Calculate total combinations
      total_combinations = (consonants.size * vowels.size) ** syllable_count
      
      return "" if combination_index >= total_combinations

      # Convert combination index to phonemes
      phonemes = [] of String
      temp_index = combination_index
      
      syllable_count.times do
        vowel_index = temp_index % vowels.size
        temp_index //= vowels.size
        cons_index = temp_index % consonants.size
        temp_index //= consonants.size
        
        phonemes << consonants[cons_index]
        phonemes << vowels[vowel_index]
      end

      @romanizer.romanize(phonemes)
    end
  end
end