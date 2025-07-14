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
    property position_rules : Hash(Symbol, Set(String))
    property weights : Hash(String, Float32)

    # Creates a new PhonemeSet with the given consonants and vowels.
    def initialize(@consonants : Set(String), @vowels : Set(String))
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