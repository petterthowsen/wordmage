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
    property phoneme_transitions : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new
    property transition_weight_factor : Float32 = 1.0
    property positional_frequencies : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new
    property gemination_patterns : Hash(String, Float32) = Hash(String, Float32).new
    property vowel_lengthening_patterns : Hash(String, Float32) = Hash(String, Float32).new
    
    # Configurable complexity costs
    property cluster_cost : Float32 = 3.0_f32
    property hiatus_cost : Float32 = 2.0_f32
    property complex_coda_cost : Float32 = 2.0_f32
    property gemination_cost : Float32 = 3.0_f32
    property vowel_lengthening_cost : Float32 = 1.0_f32

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
    # - `phoneme_transitions`: Hash mapping phoneme transitions to their frequencies
    # - `transition_weight_factor`: Weight factor for transition probabilities (default: 1.0)
    # - `positional_frequencies`: Hash mapping phonemes to their positional frequency distributions
    # - `gemination_patterns`: Hash mapping gemination patterns to their frequencies
    # - `vowel_lengthening_patterns`: Hash mapping vowel lengthening patterns to their frequencies
    # - `cluster_cost`: Cost per consonant cluster (default: 3.0)
    # - `hiatus_cost`: Cost per hiatus sequence (default: 2.0)
    # - `complex_coda_cost`: Cost per complex coda (default: 2.0)
    # - `gemination_cost`: Cost per gemination (default: 3.0)
    # - `vowel_lengthening_cost`: Cost per vowel lengthening (default: 1.0)
    def initialize(@phoneme_set : PhonemeSet, @word_spec : WordSpec, @romanizer : RomanizationMap, @mode : GenerationMode, @max_words : Int32 = 1000, @complexity_budget : Int32? = nil, @hiatus_escalation_factor : Float32 = 1.5_f32, @vowel_harmony : VowelHarmony? = nil, @gemination_probability : Float32 = 0.0_f32, @vowel_lengthening_probability : Float32 = 0.0_f32, @phoneme_transitions : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new, @transition_weight_factor : Float32 = 1.0_f32, @positional_frequencies : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new, @gemination_patterns : Hash(String, Float32) = Hash(String, Float32).new, @vowel_lengthening_patterns : Hash(String, Float32) = Hash(String, Float32).new, @cluster_cost : Float32 = 3.0_f32, @hiatus_cost : Float32 = 2.0_f32, @complex_coda_cost : Float32 = 2.0_f32, @gemination_cost : Float32 = 3.0_f32, @vowel_lengthening_cost : Float32 = 1.0_f32)
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

    # Sample a phoneme with contextual transition weights if available.
    #
    # ## Parameters
    # - `type`: Phoneme type (:consonant, :vowel)
    # - `position`: Position constraint
    # - `context`: Previous phoneme in the current word for transition weighting
    #
    # ## Returns
    # A phoneme symbol selected with transition-aware weighting
    private def sample_contextual_phoneme(type : Symbol, position : Symbol?, context : String?) : String
      if context && !@phoneme_transitions.empty? && @transition_weight_factor > 0.0
        @phoneme_set.sample_phoneme(type, position, context, @phoneme_transitions, @transition_weight_factor)
      else
        # For word-initial phonemes, use positional frequencies if available
        if position == :initial && !@positional_frequencies.empty?
          @phoneme_set.sample_phoneme(type, position, nil, @phoneme_transitions, @transition_weight_factor, @positional_frequencies)
        else
          @phoneme_set.sample_phoneme(type, position)
        end
      end
    end

    # Overload for custom groups (single character symbols)
    private def sample_contextual_phoneme(symbol : Char, position : Symbol?, context : String?) : String
      # For custom groups, fall back to regular sampling since we don't have transition data for custom symbols yet
      @phoneme_set.sample_phoneme(symbol, position)
    end

    # Generates a syllable with enhanced context while respecting template constraints
    private def generate_syllable_with_enhanced_context(template : SyllableTemplate, position : Symbol, context_phoneme : String?) : Array(String)
      # Create a context-aware PhonemeSet temporarily
      enhanced_phoneme_set = create_context_aware_phoneme_set(context_phoneme)
      
      # Use the original template generation with the enhanced PhonemeSet
      # This preserves cluster validation and all other template constraints
      template.generate(enhanced_phoneme_set, position, @romanizer)
    end

    # Creates a temporary PhonemeSet with context-aware weights for the first phoneme
    private def create_context_aware_phoneme_set(context_phoneme : String?) : PhonemeSet
      # Create a copy of the original PhonemeSet
      enhanced_set = PhonemeSet.new(@phoneme_set.consonants.to_a, @phoneme_set.vowels.to_a)
      
      # Copy original weights
      @phoneme_set.weights.each do |phoneme, weight|
        enhanced_set.add_weight(phoneme, weight)
      end
      
      # Copy custom groups
      @phoneme_set.custom_groups.each do |symbol, phonemes|
        enhanced_set.add_custom_group(symbol, phonemes.to_a)
      end
      
      # If we have context and transitions, boost weights for likely followers
      if context_phoneme && !@phoneme_transitions.empty?
        if context_transitions = @phoneme_transitions[context_phoneme]?
          context_transitions.each do |next_phoneme, frequency|
            # Find the IPA phoneme instance for the next_phoneme
            if phoneme_instance = enhanced_set.get_phoneme_by_symbol(next_phoneme)
              # Boost weight based on transition frequency
              current_weight = enhanced_set.weights[phoneme_instance]? || 1.0_f32
              boost = frequency * @transition_weight_factor
              enhanced_set.add_weight(phoneme_instance, current_weight + boost)
            end
          end
        end
      end
      
      enhanced_set
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

    # Generates words with strict budget logic
    private def generate_with_complexity_budget(syllable_count : Int32, starting_type : Symbol?, initial_budget : Int32, original_syllable_count : Int32 = syllable_count) : String
      # Initialize total budget as syllable count + complexity budget
      total_budget = syllable_count + initial_budget
      remaining_budget = total_budget.to_f32
      
      syllables = [] of Array(String)
      used_vowels = Set(String).new
      vowel_sequence = [] of String  # Track vowel sequence for harmony
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
        # Cost for prefix
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
        # Cost for suffix
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

        # Select template with strict budget constraints
        template = select_template_with_strict_budget(position, remaining_budget)

        # Use original template generation with context-aware PhonemeSet
        syllable = if !syllables.empty? && !@phoneme_transitions.empty?
          # Set context in PhonemeSet for transition-aware sampling
          context_phoneme = syllables.flatten.last?
          generate_syllable_with_enhanced_context(template, position, context_phoneme)
        else
          # Use original template generation
          template.generate(@phoneme_set, position, @romanizer)
        end
        
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
        cost = calculate_syllable_cost(syllable)
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

        # Select template with strict budget constraints
        template = select_template_with_strict_budget(position, remaining_budget)

        # Use original template generation with context-aware PhonemeSet
        syllable = if !syllables.empty? && !@phoneme_transitions.empty?
          # Set context in PhonemeSet for transition-aware sampling
          context_phoneme = syllables.flatten.last?
          generate_syllable_with_enhanced_context(template, position, context_phoneme)
        else
          # Use original template generation
          template.generate(@phoneme_set, position, @romanizer)
        end
        
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
        cost = calculate_syllable_cost(syllable)
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

        # Select syllable template with position and cost awareness
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

        # Select syllable template with position and cost awareness
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
        
        # Only geminate consonants that are in valid positions for gemination
        if i < phonemes.size - 1 && 
           can_geminate_at_position?(phonemes, i)
          
          # Calculate gemination probability for this specific consonant
          gemination_prob = calculate_gemination_probability(current_phoneme)
          
          if Random.rand < gemination_prob
            # Add the geminated consonant
            result << current_phoneme
          end
        end
        
        i += 1
      end
      
      result
    end

    # Checks if a consonant can be geminated at the given position.
    # Gemination should only occur:
    # - After a vowel (intervocalic position)
    # - Not at word boundaries
    # - Not when already doubled
    private def can_geminate_at_position?(phonemes : Array(String), position : Int32) : Bool
      current_phoneme = phonemes[position]
      
      # Must be a consonant
      return false if @phoneme_set.is_vowel?(current_phoneme)
      
      # Must not be at the end of the word
      return false if position >= phonemes.size - 1
      
      # Must not be at the beginning of the word
      return false if position == 0
      
      # Previous phoneme must be a vowel (ensures we're not in an onset cluster)
      previous_phoneme = phonemes[position - 1]
      return false unless @phoneme_set.is_vowel?(previous_phoneme)
      
      # Must not already be doubled - check if next phoneme is the same
      return false if phonemes[position + 1] == current_phoneme  # Next is same (avoid triple)
      
      # Check if we're already in a gemination sequence (look ahead for existing doubles)
      if position + 2 < phonemes.size && phonemes[position + 1] == phonemes[position + 2]
        return false  # Don't geminate if next consonant is already doubled
      end
      
      true
    end

    # Calculates the gemination probability for a specific consonant
    private def calculate_gemination_probability(consonant : String) : Float32
      # Base probability from global setting
      base_prob = @gemination_probability
      
      # If we have analysis patterns, use them to boost specific consonants
      if !@gemination_patterns.empty?
        # Look for patterns like "gg", "ll", "nn", etc.
        gemination_pattern = consonant + consonant
        pattern_frequency = @gemination_patterns[gemination_pattern]? || 0.0_f32
        
        # Combine base probability with pattern frequency
        # If pattern frequency is high, boost the probability
        enhanced_prob = base_prob + (pattern_frequency * 2.0_f32)  # Scale up pattern influence
        
        # Clamp to valid probability range
        [enhanced_prob, 1.0_f32].min
      else
        base_prob
      end
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
      vowel = sample_contextual_phoneme(:vowel, position, nil)
      
      # Generate the rest of the syllable pattern after the vowel
      remaining_pattern = template.pattern.sub(/^C*/, "")  # Remove leading consonants
      syllable = [vowel]
      
      remaining_pattern.each_char do |symbol|
        context = syllable.last? # Get the last phoneme as context
        case symbol
        when 'C'
          syllable << sample_contextual_phoneme(:consonant, position, context)
        when 'V'
          syllable << sample_contextual_phoneme(:vowel, position, context)
        else
          # Handle custom symbols
          if @phoneme_set.has_custom_group?(symbol)
            syllable << sample_contextual_phoneme(symbol, position, context)
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
           (i == 0 || phonemes[i-1] != current_phoneme) &&  # Not already doubled
           phonemes[i+1] != current_phoneme  # Next isn't same (avoid triple)
          
          # Calculate vowel lengthening probability for this specific vowel
          lengthening_prob = calculate_vowel_lengthening_probability(current_phoneme)
          
          if Random.rand < lengthening_prob
            # Add the lengthened vowel
            result << current_phoneme
          end
        end
        
        i += 1
      end
      
      result
    end

    # Calculates the vowel lengthening probability for a specific vowel
    private def calculate_vowel_lengthening_probability(vowel : String) : Float32
      # Base probability from global setting
      base_prob = @vowel_lengthening_probability
      
      # If we have analysis patterns, use them to boost specific vowels
      if !@vowel_lengthening_patterns.empty?
        # Look for patterns like "aa", "ee", "oo", etc.
        lengthening_pattern = vowel + vowel
        pattern_frequency = @vowel_lengthening_patterns[lengthening_pattern]? || 0.0_f32
        
        # Combine base probability with pattern frequency
        # If pattern frequency is high, boost the probability
        enhanced_prob = base_prob + (pattern_frequency * 2.0_f32)  # Scale up pattern influence
        
        # Clamp to valid probability range
        [enhanced_prob, 1.0_f32].min
      else
        base_prob
      end
    end

    # Generates syllable respecting budget constraints
    private def generate_syllable_with_budget(template : SyllableTemplate, position : Symbol, used_vowels : Set(String), remaining_budget : Int32) : Array(String)
      if remaining_budget <= 2
        # Low budget - use vowel harmony and simple patterns
        generate_melodic_syllable(template, position, used_vowels)
      else
        # Normal generation with budget and context
        generate_syllable_with_context(template, position, [] of String)
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
      cost = 0.0_f32
      
      # Count clusters (adjacent consonants)
      consonant_clusters = count_consonant_clusters(syllable)
      cost += consonant_clusters * @cluster_cost
      
      # Count hiatus (adjacent vowels)
      vowel_sequences = count_vowel_sequences(syllable)
      cost += vowel_sequences * @hiatus_cost
      
      # Complex codas (CC at end)
      if template.pattern.ends_with?("CC")
        cost += @complex_coda_cost
      end
      
      # Gemination cost - estimate based on probability
      if @gemination_probability > 0.0
        consonant_count = syllable.count { |p| !@phoneme_set.is_vowel?(p) }
        expected_geminations = consonant_count * @gemination_probability
        cost += expected_geminations * @gemination_cost
      end
      
      cost.to_i
    end

    # Selects a template based on strict budget constraints
    private def select_template_with_strict_budget(position : Symbol, remaining_budget : Float32) : SyllableTemplate
      # Get all applicable templates for this position
      position_weighted_templates = @word_spec.syllable_templates.select { |t| t.position_weights.has_key?(position) }
      templates_to_use = position_weighted_templates.empty? ? @word_spec.syllable_templates : position_weighted_templates
      
      # Filter templates by what we can afford with our budget
      affordable_templates = templates_to_use.select do |template|
        # Calculate template cost
        template_cost = calculate_template_cost(template)
        template_cost <= remaining_budget
      end
      
      # If no templates are affordable, use the simplest template (CV)
      if affordable_templates.empty?
        return select_simple_template(position)
      end
      
      # Select from affordable templates using their regular probability weights
      total_weight = affordable_templates.sum(&.probability)
      target = Random.rand * total_weight
      current_weight = 0.0_f32
      
      affordable_templates.each do |template|
        current_weight += template.probability
        return template if current_weight >= target
      end
      
      # Fallback to the first affordable template
      affordable_templates.first
    end
    
    # Calculate the cost of a template based on its features
    private def calculate_template_cost(template : SyllableTemplate) : Float32
      cost = 0.0_f32
      
      # Cost for consonant clusters
      if template.allowed_clusters || template.pattern.includes?("CC")
        cost += @cluster_cost
      end
      
      # Cost for complex codas
      if template.allowed_coda_clusters || template.pattern.ends_with?("CC")
        cost += @complex_coda_cost
      end
      
      # Base cost for any template (each template costs at least 1.0)
      cost += 1.0_f32
      
      cost
    end
    
    # Calculate the actual cost of a generated syllable
    private def calculate_syllable_cost(syllable : Array(String)) : Float32
      cost = 0.0_f32
      
      # Count clusters (adjacent consonants)
      consonant_clusters = count_consonant_clusters(syllable)
      cost += consonant_clusters * @cluster_cost
      
      # Count hiatus (adjacent vowels)
      vowel_sequences = count_vowel_sequences(syllable)
      cost += vowel_sequences * @hiatus_cost
      
      # Base cost for any syllable (each syllable costs at least 1.0)
      cost += 1.0_f32
      
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