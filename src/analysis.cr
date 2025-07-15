require "json"
require "./vowel_harmony"
require "./syllable_template"

module WordMage
  # Represents aggregate analysis of multiple words.
  #
  # Analysis combines data from multiple WordAnalysis instances to provide
  # statistical insights into phonological patterns, frequencies, and
  # structural tendencies. This data can be used to configure generators
  # to produce words with similar characteristics.
  #
  # This class is JSON-serializable for easy storage and transmission.
  #
  # ## Example
  # ```crystal
  # analysis = Analysis.new(
  #   phoneme_frequencies: {"n" => 0.15, "a" => 0.25, "θ" => 0.08},
  #   syllable_count_distribution: {2 => 0.3, 3 => 0.5, 4 => 0.2},
  #   average_complexity: 6.2,
  #   recommended_budget: 6
  # )
  # ```
  class Analysis
    include JSON::Serializable

    # Frequency of each phoneme across all analyzed words
    property phoneme_frequencies : Hash(String, Float32)

    # Positional frequencies: phoneme -> {position -> frequency}
    property positional_frequencies : Hash(String, Hash(String, Float32))

    # Distribution of syllable counts
    property syllable_count_distribution : Hash(Int32, Float32)

    # Distribution of syllable patterns (CV, CVC, etc.)
    property syllable_pattern_distribution : Hash(String, Float32)

    # Frequency of consonant clusters
    property cluster_patterns : Hash(String, Float32)

    # Frequency of hiatus sequences
    property hiatus_patterns : Hash(String, Float32)

    # Distribution of complexity scores
    property complexity_distribution : Hash(Int32, Float32)

    # Average complexity score across all words
    property average_complexity : Float32

    # Average syllable count across all words
    property average_syllable_count : Float32

    # Consonant to vowel ratio
    property consonant_vowel_ratio : Float32

    # Recommended complexity budget for generator
    property recommended_budget : Int32

    # Recommended syllable templates based on patterns
    property recommended_templates : Array(String)

    # Recommended hiatus probability
    property recommended_hiatus_probability : Float32

    # Recommended gemination probability based on detected patterns
    property recommended_gemination_probability : Float32

    # Most common syllable patterns
    property dominant_patterns : Array(String)

    # Vowel transition frequencies: vowel -> {next_vowel -> frequency}
    property vowel_transitions : Hash(String, Hash(String, Float32))

    # Frequency of gemination patterns
    property gemination_patterns : Hash(String, Float32)

    # Frequency of vowel lengthening patterns
    property vowel_lengthening_patterns : Hash(String, Float32)

    # Phoneme transition frequencies: phoneme -> {next_phoneme -> frequency}
    property phoneme_transitions : Hash(String, Hash(String, Float32))

    # Bigram frequencies: phoneme_pair -> frequency
    property bigram_frequencies : Hash(String, Float32)

    # Trigram frequencies: phoneme_triple -> frequency
    property trigram_frequencies : Hash(String, Float32)

    # Provided SyllableTemplate objects (when analysis uses explicit templates)
    @[JSON::Field(ignore: true)]
    property provided_templates : Array(SyllableTemplate)?

    # Creates a new Analysis with specified parameters.
    def initialize(@phoneme_frequencies : Hash(String, Float32) = Hash(String, Float32).new,
                   @positional_frequencies : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new,
                   @syllable_count_distribution : Hash(Int32, Float32) = Hash(Int32, Float32).new,
                   @syllable_pattern_distribution : Hash(String, Float32) = Hash(String, Float32).new,
                   @cluster_patterns : Hash(String, Float32) = Hash(String, Float32).new,
                   @hiatus_patterns : Hash(String, Float32) = Hash(String, Float32).new,
                   @complexity_distribution : Hash(Int32, Float32) = Hash(Int32, Float32).new,
                   @average_complexity : Float32 = 0.0_f32,
                   @average_syllable_count : Float32 = 0.0_f32,
                   @consonant_vowel_ratio : Float32 = 0.0_f32,
                   @recommended_budget : Int32 = 6,
                   @recommended_templates : Array(String) = [] of String,
                   @recommended_hiatus_probability : Float32 = 0.2_f32,
                   @recommended_gemination_probability : Float32 = 0.0_f32,
                   @dominant_patterns : Array(String) = [] of String,
                   @vowel_transitions : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new,
                   @gemination_patterns : Hash(String, Float32) = Hash(String, Float32).new,
                   @vowel_lengthening_patterns : Hash(String, Float32) = Hash(String, Float32).new,
                   @phoneme_transitions : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new,
                   @bigram_frequencies : Hash(String, Float32) = Hash(String, Float32).new,
                   @trigram_frequencies : Hash(String, Float32) = Hash(String, Float32).new,
                   @provided_templates : Array(SyllableTemplate)? = nil)
    end

    # Returns the most frequent phonemes in order.
    #
    # ## Parameters
    # - `count`: Number of top phonemes to return (default: 10)
    #
    # ## Returns
    # Array of phoneme strings ordered by frequency
    def most_frequent_phonemes(count : Int32 = 10) : Array(String)
      @phoneme_frequencies.to_a
        .sort_by { |_, freq| -freq }
        .first(count)
        .map { |phoneme, _| phoneme }
    end

    # Returns the most frequent syllable patterns.
    #
    # ## Parameters
    # - `count`: Number of top patterns to return (default: 5)
    #
    # ## Returns
    # Array of pattern strings ordered by frequency
    def most_frequent_patterns(count : Int32 = 5) : Array(String)
      @syllable_pattern_distribution.to_a
        .sort_by { |_, freq| -freq }
        .first(count)
        .map { |pattern, _| pattern }
    end

    # Returns the most frequent clusters.
    #
    # ## Parameters
    # - `count`: Number of top clusters to return (default: 10)
    #
    # ## Returns
    # Array of cluster strings ordered by frequency
    def most_frequent_clusters(count : Int32 = 10) : Array(String)
      @cluster_patterns.to_a
        .sort_by { |_, freq| -freq }
        .first(count)
        .map { |cluster, _| cluster }
    end

    # Returns phonemes that commonly appear in initial position.
    #
    # ## Parameters
    # - `threshold`: Minimum frequency threshold (default: 0.1)
    #
    # ## Returns
    # Array of phoneme strings that commonly start words
    def initial_phonemes(threshold : Float32 = 0.1_f32) : Array(String)
      result = [] of String
      
      @positional_frequencies.each do |phoneme, positions|
        if initial_freq = positions["initial"]?
          if initial_freq >= threshold
            result << phoneme
          end
        end
      end
      
      result.sort_by { |phoneme| -@positional_frequencies[phoneme]["initial"] }
    end

    # Returns phonemes that commonly appear in final position.
    #
    # ## Parameters
    # - `threshold`: Minimum frequency threshold (default: 0.1)
    #
    # ## Returns
    # Array of phoneme strings that commonly end words
    def final_phonemes(threshold : Float32 = 0.1_f32) : Array(String)
      result = [] of String
      
      @positional_frequencies.each do |phoneme, positions|
        if final_freq = positions["final"]?
          if final_freq >= threshold
            result << phoneme
          end
        end
      end
      
      result.sort_by { |phoneme| -@positional_frequencies[phoneme]["final"] }
    end

    # Calculates the diversity of phoneme usage.
    #
    # ## Returns
    # Float32 representing phoneme diversity (higher = more diverse)
    def phoneme_diversity : Float32
      return 0.0_f32 if @phoneme_frequencies.empty?
      
      # Calculate entropy-based diversity
      entropy = 0.0_f32
      @phoneme_frequencies.each do |_, freq|
        next if freq <= 0
        entropy -= freq * Math.log2(freq)
      end
      
      entropy
    end

    # Calculates the structural complexity index.
    #
    # ## Returns
    # Float32 representing overall structural complexity
    def structural_complexity : Float32
      cluster_complexity = @cluster_patterns.size * 0.3_f32
      hiatus_complexity = @hiatus_patterns.size * 0.2_f32
      pattern_complexity = @syllable_pattern_distribution.size * 0.1_f32
      
      cluster_complexity + hiatus_complexity + pattern_complexity + @average_complexity * 0.1_f32
    end

    # Determines if the analyzed language prefers simple or complex structures.
    #
    # ## Returns
    # Symbol indicating complexity preference (`:simple`, `:moderate`, `:complex`)
    def complexity_preference : Symbol
      case @average_complexity
      when 0.0...4.0
        :simple
      when 4.0...8.0
        :moderate
      else
        :complex
      end
    end

    # Calculates the optimal syllable count weights for generation.
    #
    # ## Returns
    # Hash mapping syllable counts to their optimal weights
    def optimal_syllable_weights : Hash(Int32, Float32)
      # Normalize the distribution and apply some smoothing
      total = @syllable_count_distribution.values.sum
      return {2 => 1.0_f32, 3 => 1.0_f32} if total == 0
      
      normalized = Hash(Int32, Float32).new
      @syllable_count_distribution.each do |count, freq|
        normalized[count] = freq / total
      end
      
      normalized
    end

    # Generates a summary report of the analysis.
    #
    # ## Returns
    # String containing a human-readable summary
    def summary : String
      lines = [] of String
      
      lines << "=== Language Analysis Summary ==="
      lines << "Phoneme count: #{@phoneme_frequencies.size}"
      lines << "Average syllable count: #{@average_syllable_count.round(2)}"
      lines << "Average complexity: #{@average_complexity.round(2)}"
      lines << "Consonant/vowel ratio: #{@consonant_vowel_ratio.round(2)}"
      lines << "Complexity preference: #{complexity_preference}"
      lines << "Recommended budget: #{@recommended_budget}"
      lines << ""
      lines << "Most frequent phonemes: #{most_frequent_phonemes(5).join(", ")}"
      lines << "Most frequent patterns: #{most_frequent_patterns(3).join(", ")}"
      lines << "Most frequent clusters: #{most_frequent_clusters(3).join(", ")}"
      lines << ""
      lines << "Structural complexity: #{structural_complexity.round(2)}"
      lines << "Phoneme diversity: #{phoneme_diversity.round(2)}"
      
      lines.join("\n")
    end

    # Returns the most preferred vowel transitions.
    #
    # ## Parameters
    # - `from_vowel`: The source vowel
    # - `count`: Number of top transitions to return (default: 3)
    #
    # ## Returns
    # Array of {vowel, frequency} tuples ordered by frequency
    def preferred_transitions(from_vowel : String, count : Int32 = 3) : Array({String, Float32})
      return [] of {String, Float32} unless @vowel_transitions[from_vowel]?
      
      @vowel_transitions[from_vowel].to_a
        .sort_by { |_, freq| -freq }
        .first(count)
    end

    # Generates a VowelHarmony configuration from the transition data.
    #
    # ## Parameters
    # - `strength`: Harmony strength (0.0-1.0)
    # - `threshold`: Minimum frequency to include in rules (default: 0.1)
    #
    # ## Returns
    # VowelHarmony instance configured from analysis
    def generate_vowel_harmony(strength : Float32 = 0.7_f32, threshold : Float32 = 0.1_f32) : VowelHarmony
      harmony_rules = Hash(String, Hash(String, Float32)).new
      
      @vowel_transitions.each do |from_vowel, transitions|
        # Only include transitions above threshold
        significant_transitions = transitions.select { |_, freq| freq >= threshold }
        
        if !significant_transitions.empty?
          harmony_rules[from_vowel] = significant_transitions
        end
      end
      
      VowelHarmony.new(harmony_rules, strength)
    end

    # Calculates vowel transition diversity.
    #
    # ## Returns
    # Float32 representing how diverse vowel transitions are
    def vowel_transition_diversity : Float32
      return 0.0_f32 if @vowel_transitions.empty?
      
      total_entropy = 0.0_f32
      vowel_count = 0
      
      @vowel_transitions.each do |_, transitions|
        next if transitions.empty?
        
        # Calculate entropy for this vowel's transitions
        entropy = 0.0_f32
        transitions.each do |_, freq|
          next if freq <= 0
          entropy -= freq * Math.log2(freq)
        end
        
        total_entropy += entropy
        vowel_count += 1
      end
      
      vowel_count > 0 ? total_entropy / vowel_count : 0.0_f32
    end

    # Checks if the language shows strong vowel harmony patterns.
    #
    # ## Returns
    # Symbol indicating harmony strength (`:none`, `:weak`, `:moderate`, `:strong`)
    def vowel_harmony_strength : Symbol
      return :none if @vowel_transitions.empty?
      
      strong_patterns = 0
      total_patterns = 0
      
      @vowel_transitions.each do |_, transitions|
        transitions.each do |_, freq|
          total_patterns += 1
          strong_patterns += 1 if freq > 0.6_f32
        end
      end
      
      return :none if total_patterns == 0
      
      strength_ratio = strong_patterns.to_f32 / total_patterns.to_f32
      
      case strength_ratio
      when 0.0...0.2 then :none
      when 0.2...0.4 then :weak
      when 0.4...0.7 then :moderate
      else :strong
      end
    end

    # Returns the most frequent bigrams in order.
    #
    # ## Parameters
    # - `count`: Number of top bigrams to return (default: 10)
    #
    # ## Returns
    # Array of bigram strings ordered by frequency
    def most_frequent_bigrams(count : Int32 = 10) : Array(String)
      @bigram_frequencies.to_a
        .sort_by { |_, freq| -freq }
        .first(count)
        .map { |bigram, _| bigram }
    end

    # Returns the most frequent trigrams in order.
    #
    # ## Parameters
    # - `count`: Number of top trigrams to return (default: 10)
    #
    # ## Returns
    # Array of trigram strings ordered by frequency
    def most_frequent_trigrams(count : Int32 = 10) : Array(String)
      @trigram_frequencies.to_a
        .sort_by { |_, freq| -freq }
        .first(count)
        .map { |trigram, _| trigram }
    end

    # Returns the most common phonemes that follow a given phoneme.
    #
    # ## Parameters
    # - `phoneme`: The source phoneme
    # - `count`: Number of top transitions to return (default: 5)
    #
    # ## Returns
    # Array of {next_phoneme, frequency} tuples ordered by frequency
    def most_common_followers(phoneme : String, count : Int32 = 5) : Array({String, Float32})
      return [] of {String, Float32} unless @phoneme_transitions[phoneme]?
      
      @phoneme_transitions[phoneme].to_a
        .sort_by { |_, freq| -freq }
        .first(count)
    end

    # Returns the transition probability between two phonemes.
    #
    # ## Parameters
    # - `from_phoneme`: The source phoneme
    # - `to_phoneme`: The target phoneme
    #
    # ## Returns
    # Float32 probability (0.0 if transition not found)
    def transition_probability(from_phoneme : String, to_phoneme : String) : Float32
      return 0.0_f32 unless @phoneme_transitions[from_phoneme]?
      @phoneme_transitions[from_phoneme][to_phoneme]? || 0.0_f32
    end

    # Returns the frequency of a specific bigram.
    #
    # ## Parameters
    # - `bigram`: The two-phoneme sequence
    #
    # ## Returns
    # Float32 frequency (0.0 if bigram not found)
    def bigram_frequency(bigram : String) : Float32
      @bigram_frequencies[bigram]? || 0.0_f32
    end

    # Returns the frequency of a specific trigram.
    #
    # ## Parameters
    # - `trigram`: The three-phoneme sequence
    #
    # ## Returns
    # Float32 frequency (0.0 if trigram not found)
    def trigram_frequency(trigram : String) : Float32
      @trigram_frequencies[trigram]? || 0.0_f32
    end

    # Calculates the n-gram diversity (entropy) of the language.
    #
    # ## Returns
    # Hash with bigram and trigram diversity scores
    def ngram_diversity : Hash(String, Float32)
      {
        "bigram" => calculate_entropy(@bigram_frequencies),
        "trigram" => calculate_entropy(@trigram_frequencies)
      }
    end

    # Helper method to calculate entropy of a frequency distribution.
    private def calculate_entropy(frequencies : Hash(String, Float32)) : Float32
      return 0.0_f32 if frequencies.empty?
      
      entropy = 0.0_f32
      frequencies.each do |_, freq|
        next if freq <= 0
        entropy -= freq * Math.log2(freq)
      end
      
      entropy
    end

    # Validates the analysis data for consistency.
    #
    # ## Returns
    # `true` if the analysis data is valid, `false` otherwise
    def valid? : Bool
      # Check that frequencies sum to reasonable values
      phoneme_total = @phoneme_frequencies.values.sum
      pattern_total = @syllable_pattern_distribution.values.sum
      syllable_total = @syllable_count_distribution.values.sum
      
      # Basic sanity checks
      return false if phoneme_total <= 0 || pattern_total <= 0 || syllable_total <= 0
      return false if @average_complexity < 0 || @average_syllable_count < 0
      return false if @recommended_budget < 0 || @recommended_budget > 50
      return false if @recommended_hiatus_probability < 0 || @recommended_hiatus_probability > 1
      
      true
    end
  end
end