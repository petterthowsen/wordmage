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
    property hiatus_escalation_factor : Float32

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
    def initialize(@phoneme_set : PhonemeSet, @word_spec : WordSpec, @romanizer : RomanizationMap, @mode : GenerationMode, @max_words : Int32 = 1000, @complexity_budget : Int32? = nil)
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
      # Use complexity budget if available
      if budget = @complexity_budget
        generate_with_complexity_budget(syllable_count, starting_type, budget)
      else
        generate_without_complexity_budget(syllable_count, starting_type)
      end
    end

    # Generates words with complexity budget tracking
    private def generate_with_complexity_budget(syllable_count : Int32, starting_type : Symbol?, initial_budget : Int32) : String
      syllables = [] of Array(String)
      used_vowels = Set(String).new
      remaining_budget = initial_budget
      
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

        syllable = generate_syllable_with_budget(template, position, used_vowels, remaining_budget)
        syllables << syllable
        
        # Calculate complexity cost and update budget
        cost = calculate_complexity_cost(syllable, template)
        remaining_budget = [0, remaining_budget - cost].max
        
        # Track vowels used
        syllable.each { |phoneme| used_vowels.add(phoneme) if @phoneme_set.is_vowel?(phoneme) }
      end

      phonemes = syllables.flatten

      # Check word-level constraints, starting type, and phonological issues
      if @word_spec.validate_word(phonemes) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && !has_vowel_gemination?(phonemes)
        @romanizer.romanize(phonemes)
      else
        generate_with_complexity_budget(syllable_count, starting_type, initial_budget) # Retry
      end
    end

    # Original generation without complexity budget
    private def generate_without_complexity_budget(syllable_count : Int32, starting_type : Symbol?) : String
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

      # Check word-level constraints, starting type, and phonological issues
      if @word_spec.validate_word(phonemes) && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes)
        @romanizer.romanize(phonemes)
      else
        generate_without_complexity_budget(syllable_count, starting_type) # Retry
      end
    end

    # Generates syllable respecting budget constraints
    private def generate_syllable_with_budget(template : SyllableTemplate, position : Symbol, used_vowels : Set(String), remaining_budget : Int32) : Array(String)
      if remaining_budget <= 2
        # Low budget - use vowel harmony and simple patterns
        generate_melodic_syllable(template, position, used_vowels)
      else
        # Normal generation with budget
        template.generate(@phoneme_set, position)
      end
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