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

    @sequential_state : Hash(String, Int32)?

    # Creates a new Generator.
    #
    # ## Parameters
    # - `phoneme_set`: PhonemeSet containing available consonants and vowels
    # - `word_spec`: WordSpec defining generation requirements
    # - `romanizer`: RomanizationMap for converting phonemes to text
    # - `mode`: GenerationMode (Random, Sequential, or WeightedRandom)
    # - `max_words`: Maximum words for sequential mode (default: 1000)
    def initialize(@phoneme_set : PhonemeSet, @word_spec : WordSpec, @romanizer : RomanizationMap, @mode : GenerationMode, @max_words : Int32 = 1000)
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

      # Check word-level constraints and starting type
      if @word_spec.validate_word(phonemes) && matches_starting_type?(phonemes)
        @romanizer.romanize(phonemes)
      else
        generate_random # Retry
      end
    end

    private def matches_starting_type?(phonemes : Array(String)) : Bool
      return true unless starting_type = @word_spec.starting_type

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