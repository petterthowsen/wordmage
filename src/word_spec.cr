module WordMage
  # Specifies how many syllables a word should have.
  #
  # Supports three modes:
  # - **Exact**: Always generate exactly N syllables
  # - **Range**: Generate between min and max syllables (uniform distribution)
  # - **Weighted**: Generate syllables according to weighted probabilities
  #
  # ## Example
  # ```crystal
  # exact = SyllableCountSpec.exact(3)                    # Always 3 syllables
  # range = SyllableCountSpec.range(2, 4)                 # 2-4 syllables
  # weighted = SyllableCountSpec.weighted({2 => 1.0, 3 => 3.0, 4 => 1.0})  # Prefer 3
  # ```
  struct SyllableCountSpec
    enum Type
      Exact
      Range
      Weighted
    end

    getter type : Type
    getter min : Int32
    getter max : Int32
    getter weights : Hash(Int32, Float32)?

    def initialize(@type : Type, @min : Int32, @max : Int32, @weights : Hash(Int32, Float32)? = nil)
    end

    # Creates a spec for exactly N syllables.
    def self.exact(count : Int32)
      new(Type::Exact, count, count)
    end

    # Creates a spec for a range of syllables with uniform distribution.
    def self.range(min : Int32, max : Int32)
      new(Type::Range, min, max)
    end

    # Creates a spec for weighted syllable distribution.
    #
    # ## Parameters
    # - `weights`: Hash mapping syllable counts to their relative weights
    def self.weighted(weights : Hash(Int32, Float32))
      min_count = weights.keys.min
      max_count = weights.keys.max
      new(Type::Weighted, min_count, max_count, weights)
    end

    # Generates a syllable count according to this spec.
    #
    # ## Returns
    # Number of syllables for the word
    def generate_count : Int32
      case @type
      when .exact? then @min
      when .range? then Random.rand(@min..@max)
      when .weighted? then weighted_choice(@weights.not_nil!)
      else
        raise "Unknown syllable count type: #{@type}"
      end
    end

    private def weighted_choice(weights : Hash(Int32, Float32)) : Int32
      total_weight = weights.values.sum
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      weights.each do |count, weight|
        current_weight += weight
        return count if current_weight >= target
      end

      # Fallback
      weights.keys.first
    end
  end

  # Specifies requirements for word generation.
  #
  # WordSpec combines all the rules and constraints for generating words:
  # syllable count, starting phoneme type, available templates, and constraints.
  #
  # ## Example
  # ```crystal
  # syllable_count = SyllableCountSpec.range(2, 4)
  # templates = [SyllableTemplate.new("CV"), SyllableTemplate.new("CVC")]
  # spec = WordSpec.new(
  #   syllable_count: syllable_count,
  #   syllable_templates: templates,
  #   starting_type: :vowel,
  #   word_constraints: ["rr", "ss"]  # No double consonants
  # )
  # ```
  class WordSpec
    property syllable_count : SyllableCountSpec
    property starting_type : Symbol?
    property syllable_templates : Array(SyllableTemplate)
    property word_constraints : Array(String)
    property thematic_vowel : String?
    property starts_with : String?
    property ends_with : String?

    # Creates a new WordSpec.
    #
    # ## Parameters
    # - `syllable_count`: How many syllables to generate
    # - `syllable_templates`: Available syllable patterns
    # - `starting_type`: Optional constraint on first phoneme (`:vowel` or `:consonant`)
    # - `word_constraints`: Regex patterns that words must NOT match
    # - `thematic_vowel`: Optional constraint forcing the last vowel to be this specific vowel
    # - `starts_with`: Optional constraint forcing words to start with this exact sequence
    # - `ends_with`: Optional constraint forcing words to end with this exact sequence
    def initialize(@syllable_count : SyllableCountSpec, @syllable_templates : Array(SyllableTemplate), @starting_type : Symbol? = nil, @word_constraints : Array(String) = [] of String, @thematic_vowel : String? = nil, @starts_with : String? = nil, @ends_with : String? = nil)
    end

    # Generates the number of syllables for a word.
    #
    # ## Returns
    # Number of syllables according to the syllable count spec
    def generate_syllable_count : Int32
      @syllable_count.generate_count
    end

    # Selects a syllable template for the given position.
    #
    # ## Parameters
    # - `position`: Syllable position (`:initial`, `:medial`, `:final`)
    #
    # ## Returns
    # A syllable template, respecting position weights if present
    def select_template(position : Symbol) : SyllableTemplate
      weighted_templates = @syllable_templates.select { |t| t.position_weights.has_key?(position) }

      if weighted_templates.empty?
        @syllable_templates.sample
      else
        total_weight = weighted_templates.sum { |t| t.position_weights[position] }
        target = Random.rand * total_weight
        current_weight = 0.0_f32

        weighted_templates.each do |template|
          current_weight += template.position_weights[position]
          return template if current_weight >= target
        end

        weighted_templates.first
      end
    end

    # Validates a word against constraints.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    #
    # ## Returns
    # `true` if word passes all constraints, `false` otherwise
    def validate_word(phonemes : Array(String)) : Bool
      sequence = phonemes.join
      return false unless @word_constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
      
      # Check thematic vowel constraint
      if thematic = @thematic_vowel
        return false unless validate_thematic_vowel(phonemes, thematic)
      end
      
      # Check starts_with constraint
      if prefix = @starts_with
        return false unless validate_starts_with(phonemes, prefix)
      end
      
      # Check ends_with constraint
      if suffix = @ends_with
        return false unless validate_ends_with(phonemes, suffix)
      end
      
      true
    end

    # Validates that the last vowel in the word matches the thematic vowel.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `thematic_vowel`: The required last vowel
    #
    # ## Returns
    # `true` if the last vowel matches the thematic vowel, `false` otherwise
    private def validate_thematic_vowel(phonemes : Array(String), thematic_vowel : String) : Bool
      # Find the last vowel in the word
      vowels = %w[i u y ɑ ɔ ɛ a e o]  # Standard vowel set
      
      # Search backwards for the last vowel
      phonemes.reverse_each do |phoneme|
        if vowels.includes?(phoneme)
          return phoneme == thematic_vowel
        end
      end
      
      # No vowels found - can't satisfy thematic vowel constraint
      false
    end

    # Validates that the word starts with the required sequence.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `prefix`: The required starting sequence (romanized)
    #
    # ## Returns
    # `true` if the word starts with the required sequence, `false` otherwise
    private def validate_starts_with(phonemes : Array(String), prefix : String) : Bool
      # Convert romanized prefix to phonemes (this is a simple approach)
      # In a more sophisticated system, you'd use the RomanizationMap
      prefix_phonemes = prefix.chars.map(&.to_s)
      
      # Check if word starts with the required sequence
      return false if phonemes.size < prefix_phonemes.size
      
      (0...prefix_phonemes.size).each do |i|
        return false if phonemes[i] != prefix_phonemes[i]
      end
      
      true
    end

    # Gets the required starting phonemes for the starts_with constraint.
    #
    # ## Returns
    # Array of phonemes that must start the word, or empty array if no constraint
    def get_required_prefix : Array(String)
      if prefix = @starts_with
        prefix.chars.map(&.to_s)
      else
        [] of String
      end
    end

    # Validates that the word ends with the required sequence.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `suffix`: The required ending sequence (romanized)
    #
    # ## Returns
    # `true` if the word ends with the required sequence, `false` otherwise
    private def validate_ends_with(phonemes : Array(String), suffix : String) : Bool
      # Convert romanized suffix to phonemes
      suffix_phonemes = suffix.chars.map(&.to_s)
      
      # Check if word ends with the required sequence
      return false if phonemes.size < suffix_phonemes.size
      
      # Compare the end of the word with the suffix
      start_index = phonemes.size - suffix_phonemes.size
      (0...suffix_phonemes.size).each do |i|
        return false if phonemes[start_index + i] != suffix_phonemes[i]
      end
      
      true
    end

    # Gets the required ending phonemes for the ends_with constraint.
    #
    # ## Returns
    # Array of phonemes that must end the word, or empty array if no constraint
    def get_required_suffix : Array(String)
      if suffix = @ends_with
        suffix.chars.map(&.to_s)
      else
        [] of String
      end
    end
  end
end