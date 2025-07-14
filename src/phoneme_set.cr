module WordMage
  # Manages consonants and vowels with positional constraints and weights for word generation.
  #
  # The PhonemeSet class provides a unified interface for managing phoneme inventories
  # with support for positional rules (e.g., certain phonemes only at word boundaries)
  # and weighted sampling for more realistic distribution.
  #
  # ## Example
  # ```crystal
  # phonemes = PhonemeSet.new(Set{"p", "t", "k"}, Set{"a", "e", "i"})
  # phonemes.add_phoneme("p", :consonant, [:word_initial])
  # phonemes.add_weight("p", 2.0_f32)  # Make "p" twice as likely
  # consonant = phonemes.sample_phoneme(:consonant, :word_initial)
  # ```
  class PhonemeSet
    property consonants : Set(String)
    property vowels : Set(String)
    property custom_groups : Hash(Char, Set(String))
    property position_rules : Hash(Symbol, Set(String))
    property weights : Hash(String, Float32)

    # Creates a new PhonemeSet with the given consonants and vowels.
    def initialize(@consonants : Set(String), @vowels : Set(String))
      @custom_groups = Hash(Char, Set(String)).new
      @position_rules = Hash(Symbol, Set(String)).new
      @weights = Hash(String, Float32).new
    end

    # Adds a phoneme to the set with optional positional constraints.
    #
    # ## Parameters
    # - `phoneme`: The phoneme string to add
    # - `type`: Either `:consonant` or `:vowel`
    # - `positions`: Array of position symbols (`:word_initial`, `:word_medial`, `:word_final`, etc.)
    #
    # ## Example
    # ```crystal
    # phonemes.add_phoneme("ng", :consonant, [:word_final])  # "ng" only at word end
    # ```
    def add_phoneme(phoneme : String, type : Symbol, positions : Array(Symbol) = [] of Symbol)
      case type
      when :consonant
        @consonants.add(phoneme)
      when :vowel
        @vowels.add(phoneme)
      end

      positions.each do |position|
        @position_rules[position] ||= Set(String).new
        @position_rules[position].add(phoneme)
      end
    end

    # Adds a custom phoneme group for pattern generation.
    #
    # ## Parameters
    # - `symbol`: Single character symbol for the group (e.g., 'F' for fricatives)
    # - `phonemes`: Array of phonemes belonging to this group
    # - `positions`: Optional array of position symbols for positional constraints
    #
    # ## Example
    # ```crystal
    # phonemes.add_custom_group('F', ["f", "v", "s", "z"])  # Fricatives
    # phonemes.add_custom_group('N', ["m", "n"], [:word_final])  # Nasals only at word end
    # ```
    #
    # ## Raises
    # Raises if symbol conflicts with reserved 'C' or 'V' symbols
    def add_custom_group(symbol : Char, phonemes : Array(String), positions : Array(Symbol) = [] of Symbol)
      if symbol == 'C' || symbol == 'V'
        raise "Symbol '#{symbol}' is reserved for consonants and vowels"
      end

      @custom_groups[symbol] = phonemes.to_set

      # Add positional constraints for each phoneme in the group
      phonemes.each do |phoneme|
        positions.each do |position|
          @position_rules[position] ||= Set(String).new
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
    # Array of phonemes from the custom group that can appear at the given position
    #
    # ## Raises
    # Raises if the custom group symbol is not defined
    def get_custom_group(symbol : Char, position : Symbol? = nil) : Array(String)
      unless @custom_groups.has_key?(symbol)
        raise "Custom group '#{symbol}' is not defined"
      end

      base = @custom_groups[symbol].to_a
      if position
        if rules = @position_rules[position]?
          base.select { |p| rules.includes?(p) }
        else
          base
        end
      else
        base
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
    # ```
    def add_weight(phoneme : String, weight : Float32)
      @weights[phoneme] = weight
    end

    # Returns consonants, optionally filtered by position.
    #
    # ## Parameters
    # - `position`: Optional position to filter by (e.g., `:word_initial`)
    #
    # ## Returns
    # Array of consonant strings that can appear at the given position
    def get_consonants(position : Symbol? = nil) : Array(String)
      base = @consonants.to_a
      if position
        if rules = @position_rules[position]?
          base.select { |p| rules.includes?(p) }
        else
          base
        end
      else
        base
      end
    end

    # Returns vowels, optionally filtered by position.
    #
    # ## Parameters
    # - `position`: Optional position to filter by (e.g., `:word_initial`)
    #
    # ## Returns
    # Array of vowel strings that can appear at the given position
    def get_vowels(position : Symbol? = nil) : Array(String)
      base = @vowels.to_a
      if position
        if rules = @position_rules[position]?
          base.select { |p| rules.includes?(p) }
        else
          base
        end
      else
        base
      end
    end

    # Checks if a phoneme is a vowel.
    #
    # ## Returns
    # `true` if the phoneme is in the vowels set, `false` otherwise
    def is_vowel?(phoneme : String) : Bool
      @vowels.includes?(phoneme)
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
    # This is used to determine if hiatus (vowel sequences) should be applied to custom groups
    def is_vowel_like_group?(symbol : Char) : Bool
      return false unless has_custom_group?(symbol)
      
      custom_phonemes = @custom_groups[symbol]
      custom_phonemes.all? { |phoneme| @vowels.includes?(phoneme) }
    end

    # Randomly selects a phoneme of the given type, respecting position and weights.
    #
    # ## Parameters
    # - `type`: Either `:consonant` or `:vowel`
    # - `position`: Optional position constraint
    #
    # ## Returns
    # A randomly selected phoneme string
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

    # Randomly selects a phoneme from a custom group, respecting position and weights.
    #
    # ## Parameters
    # - `symbol`: Custom group symbol (e.g., 'F' for fricatives)
    # - `position`: Optional position constraint
    #
    # ## Returns
    # A randomly selected phoneme string from the custom group
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
      weighted_candidates = candidates.select { |c| @weights.has_key?(c) }
      unweighted_candidates = candidates.reject { |c| @weights.has_key?(c) }

      if weighted_candidates.empty?
        return candidates.sample
      end

      total_weight = weighted_candidates.sum { |c| @weights[c] }
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      weighted_candidates.each do |candidate|
        current_weight += @weights[candidate]
        return candidate if current_weight >= target
      end

      # Fallback (should not reach here in normal circumstances)
      weighted_candidates.first
    end
  end
end