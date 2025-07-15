require "./IPA/ipa"

module WordMage
  # Manages consonants and vowels with positional constraints and weights for word generation.
  #
  # The PhonemeSet class provides a unified interface for managing phoneme inventories
  # with support for positional rules (e.g., certain phonemes only at word boundaries)
  # and weighted sampling for more realistic distribution.
  #
  # Internally stores IPA::Phoneme instances for rich phonological information,
  # but provides convenience methods that accept strings.
  #
  # ## Example
  # ```crystal
  # phonemes = PhonemeSet.new(["p", "t", "k"], ["a", "e", "i"])
  # phonemes.add_phoneme("p", :consonant, [:word_initial])
  # phonemes.add_weight("p", 2.0_f32)  # Make "p" twice as likely
  # consonant = phonemes.sample_phoneme(:consonant, :word_initial)
  # ```
  class PhonemeSet
    property consonants : Set(IPA::Phoneme)
    property vowels : Set(IPA::Phoneme)
    property custom_groups : Hash(Char, Set(IPA::Phoneme))
    property position_rules : Hash(Symbol, Set(IPA::Phoneme))
    property weights : Hash(IPA::Phoneme, Float32)

    # Creates a new PhonemeSet with the given consonants and vowels.
    # Accepts arrays of strings or IPA::Phoneme instances.
    def initialize(consonants : Array(String | IPA::Phoneme), vowels : Array(String | IPA::Phoneme))
      @consonants = resolve_phonemes(consonants).to_set
      @vowels = resolve_phonemes(vowels).to_set
      @custom_groups = Hash(Char, Set(IPA::Phoneme)).new
      @position_rules = Hash(Symbol, Set(IPA::Phoneme)).new
      @weights = Hash(IPA::Phoneme, Float32).new
    end

    # Backward compatibility constructor for string arrays
    def initialize(consonants : Array(String), vowels : Array(String))
      @consonants = resolve_phonemes(consonants.map(&.as(String | IPA::Phoneme))).to_set
      @vowels = resolve_phonemes(vowels.map(&.as(String | IPA::Phoneme))).to_set
      @custom_groups = Hash(Char, Set(IPA::Phoneme)).new
      @position_rules = Hash(Symbol, Set(IPA::Phoneme)).new
      @weights = Hash(IPA::Phoneme, Float32).new
    end

    # Backward compatibility constructor for string sets
    def initialize(consonants : Set(String), vowels : Set(String))
      @consonants = resolve_phonemes(consonants.to_a.map(&.as(String | IPA::Phoneme))).to_set
      @vowels = resolve_phonemes(vowels.to_a.map(&.as(String | IPA::Phoneme))).to_set
      @custom_groups = Hash(Char, Set(IPA::Phoneme)).new
      @position_rules = Hash(Symbol, Set(IPA::Phoneme)).new
      @weights = Hash(IPA::Phoneme, Float32).new
    end

    # Adds a phoneme to the set with optional positional constraints.
    #
    # ## Parameters
    # - `phoneme`: The phoneme string or IPA::Phoneme instance to add
    # - `type`: Either `:consonant` or `:vowel`
    # - `positions`: Array of position symbols (`:word_initial`, `:word_medial`, `:word_final`, etc.)
    #
    # ## Example
    # ```crystal
    # phonemes.add_phoneme("ng", :consonant, [:word_final])  # "ng" only at word end
    # phonemes.add_phoneme(IPA::Utils.find_phoneme("p").not_nil!, :consonant, [:word_initial])
    # ```
    def add_phoneme(phoneme : String | IPA::Phoneme, type : Symbol, positions : Array(Symbol) = [] of Symbol)
      phoneme_instance = resolve_phoneme(phoneme)
      
      case type
      when :consonant
        @consonants.add(phoneme_instance)
      when :vowel
        @vowels.add(phoneme_instance)
      end

      positions.each do |position|
        @position_rules[position] ||= Set(IPA::Phoneme).new
        @position_rules[position].add(phoneme_instance)
      end
    end

    # Adds a custom phoneme group for pattern generation.
    #
    # ## Parameters
    # - `symbol`: Single character symbol for the group (e.g., 'F' for fricatives)
    # - `phonemes`: Array of phonemes (strings or IPA::Phoneme instances) belonging to this group
    # - `positions`: Optional array of position symbols for positional constraints
    #
    # ## Example
    # ```crystal
    # phonemes.add_custom_group('F', ["f", "v", "s", "z"])  # Fricatives
    # phonemes.add_custom_group('N', ["m", "n"], [:word_final])  # Nasals only at word end
    # phonemes.add_custom_group('P', [IPA::Utils.find_phoneme("p").not_nil!])  # Using IPA::Phoneme
    # ```
    #
    # ## Raises
    # Raises if symbol conflicts with reserved 'C' or 'V' symbols
    def add_custom_group(symbol : Char, phonemes : Array(String | IPA::Phoneme), positions : Array(Symbol) = [] of Symbol)
      if symbol == 'C' || symbol == 'V'
        raise "Symbol '#{symbol}' is reserved for consonants and vowels"
      end

      phoneme_instances = resolve_phonemes(phonemes).to_set
      @custom_groups[symbol] = phoneme_instances

      # Add positional constraints for each phoneme in the group
      phoneme_instances.each do |phoneme|
        positions.each do |position|
          @position_rules[position] ||= Set(IPA::Phoneme).new
          @position_rules[position].add(phoneme)
        end
      end
    end

    # Returns phonemes from a custom group, optionally filtered by position.
    #
    # ## Parameters
    # - `symbol`: Custom group symbol
    # - `position`: Optional position to filter by
    #
    # ## Returns
    # Array of phoneme symbols from the custom group that can appear at the given position
    #
    # ## Raises
    # Raises if the custom group symbol is not defined
    def get_custom_group(symbol : Char, position : Symbol? = nil) : Array(String)
      unless @custom_groups.has_key?(symbol)
        raise "Custom group '#{symbol}' is not defined"
      end

      base = @custom_groups[symbol]
      if position
        if rules = @position_rules[position]?
          filtered = base.select { |p| rules.includes?(p) }
          filtered.map(&.symbol).to_a
        else
          base.map(&.symbol).to_a
        end
      else
        base.map(&.symbol).to_a
      end
    end

    # Checks if a custom group symbol is defined.
    #
    # ## Parameters
    # - `symbol`: Custom group symbol to check
    #
    # ## Returns
    # `true` if the custom group is defined, `false` otherwise
    def has_custom_group?(symbol : Char) : Bool
      @custom_groups.has_key?(symbol)
    end

    # Assigns a weight to a phoneme for weighted sampling.
    #
    # Phonemes with higher weights are more likely to be selected.
    # Default weight is 1.0 for all phonemes.
    #
    # ## Example
    # ```crystal
    # phonemes.add_weight("p", 3.0_f32)  # "p" is 3x more likely than default
    # phonemes.add_weight(IPA::Utils.find_phoneme("p").not_nil!, 3.0_f32)  # Using IPA::Phoneme
    # ```
    def add_weight(phoneme : String | IPA::Phoneme, weight : Float32)
      phoneme_instance = resolve_phoneme(phoneme)
      @weights[phoneme_instance] = weight
    end

    # Returns consonants, optionally filtered by position.
    #
    # ## Parameters
    # - `position`: Optional position to filter by (e.g., `:word_initial`)
    #
    # ## Returns
    # Array of consonant symbols that can appear at the given position
    def get_consonants(position : Symbol? = nil) : Array(String)
      base = @consonants
      if position
        if rules = @position_rules[position]?
          filtered = base.select { |p| rules.includes?(p) }
          filtered.map(&.symbol).to_a
        else
          base.map(&.symbol).to_a
        end
      else
        base.map(&.symbol).to_a
      end
    end

    # Returns vowels, optionally filtered by position.
    #
    # ## Parameters
    # - `position`: Optional position to filter by (e.g., `:word_initial`)
    #
    # ## Returns
    # Array of vowel symbols that can appear at the given position
    def get_vowels(position : Symbol? = nil) : Array(String)
      base = @vowels
      if position
        if rules = @position_rules[position]?
          filtered = base.select { |p| rules.includes?(p) }
          filtered.map(&.symbol).to_a
        else
          base.map(&.symbol).to_a
        end
      else
        base.map(&.symbol).to_a
      end
    end

    # Checks if a phoneme is a vowel.
    #
    # ## Returns
    # `true` if the phoneme is in the vowels set or recognized by IPA classification, `false` otherwise
    #
    # ## Note
    # First checks the local vowels set, then falls back to IPA classification for broader coverage
    def is_vowel?(phoneme : String) : Bool
      @vowels.any?(&.symbol.== phoneme) || IPA::Utils.is_vowel?(phoneme)
    end

    # Checks if a custom group symbol should be treated as vowel-like for hiatus generation.
    #
    # ## Parameters
    # - `symbol`: Custom group symbol to check
    #
    # ## Returns
    # `true` if the custom group contains only vowels, `false` otherwise
    #
    # ## Note
    # This is used to determine if hiatus (vowel sequences) should be applied to custom groups.
    # Uses the IPA module for accurate vowel detection beyond just the local vowels set.
    def is_vowel_like_group?(symbol : Char) : Bool
      return false unless has_custom_group?(symbol)
      
      custom_phonemes = @custom_groups[symbol]
      custom_phonemes.all? { |phoneme| 
        # Check both local vowels set and IPA classification
        @vowels.includes?(phoneme) || IPA::Utils.is_vowel?(phoneme.symbol)
      }
    end

    # Randomly selects a phoneme of the given type, respecting position and weights.
    #
    # ## Parameters
    # - `type`: Either `:consonant` or `:vowel`
    # - `position`: Optional position constraint
    #
    # ## Returns
    # A randomly selected phoneme symbol
    #
    # ## Raises
    # Raises if no candidates are available for the given type and position
    def sample_phoneme(type : Symbol, position : Symbol? = nil) : String
      candidates = case type
                   when :consonant then get_consonants(position)
                   when :vowel then get_vowels(position)
                   else [] of String
                   end

      raise "No candidates available for type #{type} at position #{position}" if candidates.empty?

      if @weights.empty?
        candidates.sample
      else
        weighted_sample(candidates)
      end
    end

    # Randomly selects a phoneme from the specified type with contextual transition weights.
    #
    # ## Parameters
    # - `type`: Either `:consonant` or `:vowel`
    # - `position`: Optional position constraint
    # - `context`: Previous phoneme for transition weighting
    # - `transitions`: Hash mapping phoneme transitions to frequencies
    # - `transition_weight_factor`: Weight factor for transition probabilities
    #
    # ## Returns
    # A randomly selected phoneme symbol that respects constraints and transition probabilities
    def sample_phoneme(type : Symbol, position : Symbol?, context : String?, transitions : Hash(String, Hash(String, Float32)), transition_weight_factor : Float32) : String
      candidates = case type
                   when :consonant then get_consonants(position)
                   when :vowel then get_vowels(position)
                   else [] of String
                   end
      raise "No candidates available for type #{type} at position #{position}" if candidates.empty?
      
      # If no context or transitions, fall back to regular sampling
      if context.nil? || transitions.empty? || !transitions[context]?
        if @weights.empty?
          return candidates.sample
        else
          return weighted_sample(candidates)
        end
      end
      
      # Use transition-aware weighted sampling
      transition_weighted_sample(candidates, context, transitions, transition_weight_factor)
    end

    # Randomly selects a phoneme using positional frequencies for word-initial selection.
    #
    # ## Parameters
    # - `type`: Either `:consonant` or `:vowel`
    # - `position`: Optional position constraint
    # - `context`: Previous phoneme for transition weighting (nil for word-initial)
    # - `transitions`: Hash mapping phoneme transitions to frequencies
    # - `transition_weight_factor`: Weight factor for transition probabilities
    # - `positional_frequencies`: Hash mapping phonemes to their positional frequency distributions
    #
    # ## Returns
    # A randomly selected phoneme symbol that respects constraints and positional frequencies
    def sample_phoneme(type : Symbol, position : Symbol?, context : String?, transitions : Hash(String, Hash(String, Float32)), transition_weight_factor : Float32, positional_frequencies : Hash(String, Hash(String, Float32))) : String
      candidates = case type
                   when :consonant then get_consonants(position)
                   when :vowel then get_vowels(position)
                   else [] of String
                   end
      raise "No candidates available for type #{type} at position #{position}" if candidates.empty?
      
      # Use positional frequencies for word-initial selection
      if position == :initial && !positional_frequencies.empty?
        positional_weighted_sample(candidates, position, positional_frequencies, transition_weight_factor)
      else
        # Fall back to regular contextual sampling
        sample_phoneme(type, position, context, transitions, transition_weight_factor)
      end
    end

    # Randomly selects a phoneme from a custom group, respecting position and weights.
    #
    # ## Parameters
    # - `symbol`: Custom group symbol (e.g., 'F' for fricatives)
    # - `position`: Optional position constraint
    #
    # ## Returns
    # A randomly selected phoneme symbol from the custom group
    #
    # ## Raises
    # Raises if the custom group is not defined or no candidates are available
    def sample_phoneme(symbol : Char, position : Symbol? = nil) : String
      candidates = get_custom_group(symbol, position)

      raise "No candidates available for custom group '#{symbol}' at position #{position}" if candidates.empty?

      if @weights.empty?
        candidates.sample
      else
        weighted_sample(candidates)
      end
    end

    private def weighted_sample(candidates : Array(String)) : String
      # Get phoneme instances for candidates to check weights
      candidate_phonemes = candidates.map { |symbol| find_phoneme_by_symbol(symbol) }.compact
      
      weighted_candidates = candidate_phonemes.select { |p| @weights.has_key?(p) }
      
      if weighted_candidates.empty?
        return candidates.sample
      end

      total_weight = weighted_candidates.sum { |p| @weights[p] }
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      weighted_candidates.each do |candidate|
        current_weight += @weights[candidate]
        return candidate.symbol if current_weight >= target
      end

      # Fallback (should not reach here in normal circumstances)
      weighted_candidates.first.symbol
    end

    # Weighted sampling that combines base weights with transition probabilities.
    #
    # ## Parameters
    # - `candidates`: Array of candidate phoneme symbols
    # - `context`: Previous phoneme for transition weighting
    # - `transitions`: Hash mapping phoneme transitions to frequencies
    # - `transition_weight_factor`: Weight factor for transition probabilities
    #
    # ## Returns
    # A randomly selected phoneme symbol based on combined weights
    private def transition_weighted_sample(candidates : Array(String), context : String, transitions : Hash(String, Hash(String, Float32)), transition_weight_factor : Float32) : String
      # Calculate combined weights for each candidate
      weighted_candidates = [] of {String, Float32}
      
      candidates.each do |candidate|
        # Base weight from phoneme frequency
        base_weight = 1.0_f32
        if phoneme_instance = find_phoneme_by_symbol(candidate)
          base_weight = @weights[phoneme_instance]? || 1.0_f32
        end
        
        # Transition weight from context
        transition_weight = 0.0_f32
        if context_transitions = transitions[context]?
          transition_weight = context_transitions[candidate]? || 0.0_f32
        end
        
        # Combine weights: base weight + (transition probability * factor)
        combined_weight = base_weight + (transition_weight * transition_weight_factor)
        
        # Ensure minimum weight to allow some randomness
        combined_weight = [combined_weight, 0.1_f32].max
        
        weighted_candidates << {candidate, combined_weight}
      end
      
      # Select based on combined weights
      total_weight = weighted_candidates.sum(&.last)
      threshold = Random.rand * total_weight
      
      cumulative_weight = 0.0_f32
      weighted_candidates.each do |candidate, weight|
        cumulative_weight += weight
        if cumulative_weight >= threshold
          return candidate
        end
      end
      
      # Fallback
      weighted_candidates.last.first
    end

    # Weighted sampling that uses positional frequencies for word-initial phonemes.
    #
    # ## Parameters
    # - `candidates`: Array of candidate phoneme symbols
    # - `position`: Word position (:initial, :medial, :final)
    # - `positional_frequencies`: Hash mapping phonemes to their positional frequency distributions
    # - `weight_factor`: Weight factor for positional frequencies
    #
    # ## Returns
    # A randomly selected phoneme symbol based on positional frequencies
    private def positional_weighted_sample(candidates : Array(String), position : Symbol, positional_frequencies : Hash(String, Hash(String, Float32)), weight_factor : Float32) : String
      weighted_candidates = [] of {String, Float32}
      position_key = position.to_s
      
      candidates.each do |candidate|
        # Base weight from phoneme frequency
        base_weight = 1.0_f32
        if phoneme_instance = find_phoneme_by_symbol(candidate)
          base_weight = @weights[phoneme_instance]? || 1.0_f32
        end
        
        # Positional weight
        positional_weight = 0.0_f32
        if candidate_positions = positional_frequencies[candidate]?
          positional_weight = candidate_positions[position_key]? || 0.0_f32
        end
        
        # Combine weights: base weight + (positional frequency * factor)
        combined_weight = base_weight + (positional_weight * weight_factor)
        
        # Ensure minimum weight to allow some randomness
        combined_weight = [combined_weight, 0.1_f32].max
        
        weighted_candidates << {candidate, combined_weight}
      end
      
      # Select based on combined weights
      total_weight = weighted_candidates.sum(&.last)
      threshold = Random.rand * total_weight
      
      cumulative_weight = 0.0_f32
      weighted_candidates.each do |candidate, weight|
        cumulative_weight += weight
        if cumulative_weight >= threshold
          return candidate
        end
      end
      
      # Fallback
      weighted_candidates.last.first
    end

    # Public method to find a phoneme by its symbol
    def get_phoneme_by_symbol(symbol : String) : IPA::Phoneme?
      (@consonants + @vowels).find { |p| p.symbol == symbol }
    end

    # Helper method to resolve a single phoneme input to an IPA::Phoneme instance
    private def resolve_phoneme(input : String | IPA::Phoneme) : IPA::Phoneme
      case input
      when String
        # Try to find in BasicPhonemes first
        found = IPA::Utils.find_phoneme(input)
        return found if found
        
        # If not found, create a basic phoneme
        # We'll assume it's a consonant if it's not a known vowel
        if IPA::Utils.is_vowel?(input)
          # Create a basic vowel (this is a fallback for unknown vowels)
          IPA::Vowel.new(input, input, :Mid, :Central, rounded: false)
        else
          # Create a basic consonant (this is a fallback for unknown consonants)
          IPA::Consonant.new(input, input, :Approximant, :Alveolar, voiced: true)
        end
      when IPA::Phoneme
        input
      else
        raise "Invalid phoneme input type"
      end
    end

    # Helper method to resolve an array of phoneme inputs to IPA::Phoneme instances
    private def resolve_phonemes(inputs : Array(String | IPA::Phoneme)) : Array(IPA::Phoneme)
      inputs.map { |input| resolve_phoneme(input) }
    end

    # Helper method to find a phoneme instance by its symbol
    private def find_phoneme_by_symbol(symbol : String) : IPA::Phoneme?
      # Search in consonants
      @consonants.each do |p|
        return p if p.symbol == symbol
      end
      
      # Search in vowels
      @vowels.each do |p|
        return p if p.symbol == symbol
      end
      
      # Search in custom groups
      @custom_groups.each_value do |group|
        group.each do |p|
          return p if p.symbol == symbol
        end
      end
      
      nil
    end

    # Convenience method to get consonant symbols as strings for backward compatibility
    def consonant_symbols : Set(String)
      @consonants.map(&.symbol).to_set
    end

    # Convenience method to get vowel symbols as strings for backward compatibility
    def vowel_symbols : Set(String)
      @vowels.map(&.symbol).to_set
    end

    # Get consonant phoneme instances directly
    def consonant_phonemes : Set(IPA::Phoneme)
      @consonants
    end

    # Get vowel phoneme instances directly
    def vowel_phonemes : Set(IPA::Phoneme)
      @vowels
    end

    # Get weights mapped by symbol strings for backward compatibility
    def symbol_weights : Hash(String, Float32)
      result = Hash(String, Float32).new
      @weights.each do |phoneme, weight|
        result[phoneme.symbol] = weight
      end
      result
    end

    # Get weights mapped by phoneme instances directly
    def phoneme_weights : Hash(IPA::Phoneme, Float32)
      @weights
    end
  end
end