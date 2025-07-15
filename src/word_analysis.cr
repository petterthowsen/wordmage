require "json"

module WordMage
  # Represents the analysis of a single word.
  #
  # WordAnalysis captures detailed information about a word's structure,
  # including syllable patterns, phoneme counts, complexity measures,
  # and structural features like clusters and hiatus sequences.
  #
  # This class is JSON-serializable for easy storage and transmission.
  #
  # ## Example
  # ```crystal
  # analysis = WordAnalysis.new(
  #   syllable_count: 3,
  #   consonant_count: 4,
  #   vowel_count: 3,
  #   hiatus_count: 1,
  #   cluster_count: 2,
  #   complexity_score: 8,
  #   phonemes: ["n", "a", "z", "a", "g", "o", "n"],
  #   syllable_patterns: ["CV", "CV", "CVC"]
  # )
  # ```
  class WordAnalysis
    include JSON::Serializable

    # Number of syllables in the word
    property syllable_count : Int32

    # Number of consonant phonemes
    property consonant_count : Int32

    # Number of vowel phonemes
    property vowel_count : Int32

    # Number of hiatus sequences (adjacent vowels)
    property hiatus_count : Int32

    # Number of consonant clusters (adjacent consonants)
    property cluster_count : Int32

    # Complexity score based on clusters, hiatus, and patterns
    property complexity_score : Int32

    # Array of phonemes in the word
    property phonemes : Array(String)

    # Syllable patterns (e.g., ["CV", "CVC", "CV"])
    property syllable_patterns : Array(String)

    # Consonant clusters found in the word
    property clusters : Array(String)

    # Hiatus sequences found in the word
    property hiatus_sequences : Array(String)

    # Phoneme positions (initial, medial, final)
    property phoneme_positions : Hash(Symbol, Array(String))

    # Gemination sequences found in the word
    property gemination_sequences : Array(String)

    # Vowel lengthening sequences found in the word
    property vowel_lengthening_sequences : Array(String)

    # Phoneme transitions in the word (phoneme -> next_phoneme)
    property phoneme_transitions : Array({String, String})

    # Bigrams found in the word
    property bigrams : Array(String)

    # Trigrams found in the word
    property trigrams : Array(String)

    # Creates a new WordAnalysis.
    #
    # ## Parameters
    # - `syllable_count`: Number of syllables
    # - `consonant_count`: Number of consonants
    # - `vowel_count`: Number of vowels
    # - `hiatus_count`: Number of hiatus sequences
    # - `cluster_count`: Number of consonant clusters
    # - `complexity_score`: Overall complexity score
    # - `phonemes`: Array of phonemes
    # - `syllable_patterns`: Array of syllable patterns
    # - `clusters`: Array of consonant clusters
    # - `hiatus_sequences`: Array of hiatus sequences
    # - `phoneme_positions`: Hash mapping positions to arrays of phonemes
    # - `gemination_sequences`: Array of gemination sequences
    # - `vowel_lengthening_sequences`: Array of vowel lengthening sequences
    # - `phoneme_transitions`: Array of phoneme transition tuples
    # - `bigrams`: Array of bigrams
    # - `trigrams`: Array of trigrams
    def initialize(@syllable_count : Int32, @consonant_count : Int32, @vowel_count : Int32, 
                   @hiatus_count : Int32, @cluster_count : Int32, @complexity_score : Int32,
                   @phonemes : Array(String), @syllable_patterns : Array(String),
                   @clusters : Array(String) = [] of String, @hiatus_sequences : Array(String) = [] of String,
                   @phoneme_positions : Hash(Symbol, Array(String)) = Hash(Symbol, Array(String)).new,
                   @gemination_sequences : Array(String) = [] of String, @vowel_lengthening_sequences : Array(String) = [] of String,
                   @phoneme_transitions : Array({String, String}) = [] of {String, String}, @bigrams : Array(String) = [] of String, @trigrams : Array(String) = [] of String)
    end

    # Returns the ratio of consonants to vowels.
    #
    # ## Returns
    # Float32 representing the consonant-to-vowel ratio
    def consonant_vowel_ratio : Float32
      return 0.0_f32 if @vowel_count == 0
      @consonant_count.to_f32 / @vowel_count.to_f32
    end

    # Returns the average syllable complexity.
    #
    # ## Returns
    # Float32 representing complexity per syllable
    def average_syllable_complexity : Float32
      return 0.0_f32 if @syllable_count == 0
      @complexity_score.to_f32 / @syllable_count.to_f32
    end

    # Checks if the word contains clusters.
    #
    # ## Returns
    # `true` if the word has consonant clusters, `false` otherwise
    def has_clusters? : Bool
      @cluster_count > 0
    end

    # Checks if the word contains hiatus sequences.
    #
    # ## Returns
    # `true` if the word has vowel sequences, `false` otherwise
    def has_hiatus? : Bool
      @hiatus_count > 0
    end

    # Checks if the word contains gemination sequences.
    #
    # ## Returns
    # `true` if the word has consonant gemination, `false` otherwise
    def has_gemination? : Bool
      !@gemination_sequences.empty?
    end

    # Checks if the word contains vowel lengthening sequences.
    #
    # ## Returns
    # `true` if the word has vowel lengthening, `false` otherwise
    def has_vowel_lengthening? : Bool
      !@vowel_lengthening_sequences.empty?
    end

    # Returns the most common syllable pattern.
    #
    # ## Returns
    # String representing the most frequent syllable pattern
    def dominant_syllable_pattern : String
      return "CV" if @syllable_patterns.empty?
      
      pattern_counts = Hash(String, Int32).new(0)
      @syllable_patterns.each { |pattern| pattern_counts[pattern] += 1 }
      
      pattern_counts.max_by { |_, count| count }.first
    end

    # Returns a summary of the word analysis.
    #
    # ## Returns
    # String with key analysis metrics
    def summary : String
      "#{@syllable_count} syllables, #{@consonant_count}C/#{@vowel_count}V, " +
      "#{@cluster_count} clusters, #{@hiatus_count} hiatus, complexity: #{@complexity_score}"
    end
  end
end