require "./IPA/ipa"

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
    property consonants : Set(IPA::Phoneme)
    property vowels : Set(IPA::Phoneme)
    property custom_groups : Hash(Char, Set(IPA::Phoneme))
    property position_rules : Hash(Symbol, Set(IPA::Phoneme))
    property weights : Hash(IPA::Phoneme, Float32)

    # Creates a new PhonemeSet with the given consonants and vowels.
    # Accepts either String symbols or IPA::Phoneme instances.
    def initialize(consonants : Set(IPA::Phoneme) | Array(String | IPA::Phoneme), vowels : Set(IPA::Phoneme) | Array(String | IPA::Phoneme))
      @consonants = resolve_phoneme_set(consonants)
      @vowels = resolve_phoneme_set(vowels)
      @custom_groups = Hash(Char, Set(IPA::Phoneme)).new
      @position_rules = Hash(Symbol, Set(IPA::Phoneme)).new
      @weights = Hash(IPA::Phoneme, Float32).new
    end

    # Backward compatibility constructor for string sets
    def initialize(consonants : Set(String), vowels : Set(String))
      @consonants = resolve_string_set_to_phonemes(consonants)
      @vowels = resolve_string_set_to_phonemes(vowels)
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
      phoneme_instance = resolve_to_phoneme(phoneme)
      
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

    # Backward compatibility overload for string phonemes
    def add_phoneme(phoneme : String, type : Symbol, positions : Array(Symbol) = [] of Symbol)
      phoneme_instance = resolve_to_phoneme(phoneme)
      
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

      phoneme_symbols = phonemes.map { |p| resolve_phoneme_symbol(p) }
      @custom_groups[symbol] = phoneme_symbols.to_set

      # Add positional constraints for each phoneme in the group
      phoneme_symbols.each do |phoneme|
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
    # phonemes.add_weight(IPA::Utils.find_phoneme("p").not_nil!, 3.0_f32)  # Using IPA::Phoneme
    # ```
    def add_weight(phoneme : String | IPA::Phoneme, weight : Float32)
      phoneme_symbol = resolve_phoneme_symbol(phoneme)
      @weights[phoneme_symbol] = weight
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
    # `true` if the phoneme is in the vowels set or recognized by IPA classification, `false` otherwise
    #
    # ## Note
    # First checks the local vowels set, then falls back to IPA classification for broader coverage
    def is_vowel?(phoneme : String) : Bool
      @vowels.includes?(phoneme) || IPA::Utils.is_vowel?(phoneme)
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
        @vowels.includes?(phoneme) || IPA::Utils.is_vowel?(phoneme)
      }
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

    # Helper method to resolve a phoneme input to its symbol string
    private def resolve_phoneme_symbol(input : String | IPA::Phoneme) : String
      case input
      when String
        input
      when IPA::Phoneme
        input.symbol
      else
        raise "Invalid phoneme input type"
      end
    end

    # Helper method to resolve phoneme collection to Set(String)
    private def resolve_phoneme_set(input : Set(String) | Array(String | IPA::Phoneme)) : Set(String)
      case input
      when Set(String)
        input
      when Array
        input.map { |p| resolve_phoneme_symbol(p) }.to_set
      else
        raise "Invalid phoneme collection type"
      end
    end
  end
end