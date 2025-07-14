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

    # Creates a new WordSpec.
    #
    # ## Parameters
    # - `syllable_count`: How many syllables to generate
    # - `syllable_templates`: Available syllable patterns
    # - `starting_type`: Optional constraint on first phoneme (`:vowel` or `:consonant`)
    # - `word_constraints`: Regex patterns that words must NOT match
    def initialize(@syllable_count : SyllableCountSpec, @syllable_templates : Array(SyllableTemplate), @starting_type : Symbol? = nil, @word_constraints : Array(String) = [] of String)
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
      @word_constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
    end
  end
end