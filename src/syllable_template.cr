module WordMage
  # Defines syllable structure patterns with constraints and hiatus generation.
  #
  # SyllableTemplate specifies how syllables should be constructed using pattern
  # strings like "CV" (consonant-vowel), "CVC" (consonant-vowel-consonant), etc.
  # Supports hiatus (vowel sequences) and validation constraints.
  #
  # ## Pattern Symbols
  # - `C`: Consonant
  # - `V`: Vowel (may become VV with hiatus)
  #
  # ## Example
  # ```crystal
  # template = SyllableTemplate.new("CCV", ["rr"], hiatus_probability: 0.3_f32)
  # syllable = template.generate(phoneme_set, :initial)  # ["p", "r", "a", "e"]
  # ```
  class SyllableTemplate
    property pattern : String
    property constraints : Array(String)
    property hiatus_probability : Float32
    property position_weights : Hash(Symbol, Float32)

    # Creates a new syllable template.
    #
    # ## Parameters
    # - `pattern`: Pattern string (e.g., "CV", "CVC", "CCV")
    # - `constraints`: Regex patterns that syllables must NOT match
    # - `hiatus_probability`: Chance (0.0-1.0) that V becomes VV
    # - `position_weights`: Weights for using this template at different positions
    def initialize(@pattern : String, @constraints : Array(String) = [] of String, @hiatus_probability : Float32 = 0.0_f32, @position_weights : Hash(Symbol, Float32) = Hash(Symbol, Float32).new)
    end

    # Generates a syllable using this template.
    #
    # ## Parameters
    # - `phonemes`: PhonemeSet to sample from
    # - `position`: Syllable position (`:initial`, `:medial`, `:final`)
    #
    # ## Returns
    # Array of phoneme strings forming the syllable
    #
    # ## Note
    # Automatically retries if constraints are violated
    def generate(phonemes : PhonemeSet, position : Symbol) : Array(String)
      syllable = [] of String

      @pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << phonemes.sample_phoneme(:consonant, position)
        when 'V'
          if allows_hiatus? && Random.rand < @hiatus_probability
            syllable << phonemes.sample_phoneme(:vowel, position)
            syllable << phonemes.sample_phoneme(:vowel, position)
          else
            syllable << phonemes.sample_phoneme(:vowel, position)
          end
        end
      end

      # Retry if constraints violated
      if validate(syllable)
        syllable
      else
        generate(phonemes, position)
      end
    end

    # Checks if this template can generate hiatus (vowel sequences).
    #
    # ## Returns
    # `true` if hiatus_probability > 0, `false` otherwise
    def allows_hiatus? : Bool
      @hiatus_probability > 0.0_f32
    end

    # Validates a syllable against constraints.
    #
    # ## Parameters
    # - `syllable`: Array of phonemes to validate
    #
    # ## Returns
    # `true` if syllable passes all constraints, `false` otherwise
    def validate(syllable : Array(String)) : Bool
      sequence = syllable.join
      @constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
    end
  end
end