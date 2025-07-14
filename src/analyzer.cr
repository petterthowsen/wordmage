require "./word_analyzer"
require "./analysis"

module WordMage
  # Analyzes sets of words to extract aggregate phonological patterns.
  #
  # Analyzer processes multiple words to identify statistical patterns
  # in phoneme usage, syllable structure, complexity, and other linguistic
  # features. The results can be used to configure generators to produce
  # words with similar characteristics.
  #
  # ## Example
  # ```crystal
  # romanization = RomanizationMap.new({
  #   "th" => "θ", "dr" => "dr", "a" => "ɑ", "e" => "ɛ", "o" => "ɔ"
  # })
  # analyzer = Analyzer.new(romanization)
  # words = ["nazagon", "thadrae", "drayeki", "ora", "varanaya"]
  # analysis = analyzer.analyze(words)
  # puts analysis.average_complexity  # 6.2
  # puts analysis.recommended_budget  # 6
  # ```
  class Analyzer
    @word_analyzer : WordAnalyzer

    # Creates a new Analyzer.
    #
    # ## Parameters
    # - `romanization_map`: RomanizationMap for converting romanized text to phonemes
    def initialize(@romanization_map : RomanizationMap)
      @word_analyzer = WordAnalyzer.new(@romanization_map)
    end

    # Analyzes a set of words to extract aggregate patterns.
    #
    # ## Parameters
    # - `words`: Array of romanized words to analyze
    #
    # ## Returns
    # Analysis containing aggregate statistics and recommendations
    #
    # ## Example
    # ```crystal
    # analysis = analyzer.analyze(["nazagon", "thadrae", "drayeki"])
    # puts analysis.phoneme_frequencies["a"]  # 0.25
    # puts analysis.recommended_templates     # ["CV", "CVC", "CCV"]
    # ```
    def analyze(words : Array(String)) : Analysis
      return Analysis.new if words.empty?
      
      # Analyze each word individually
      word_analyses = words.map { |word| @word_analyzer.analyze(word) }
      
      # Aggregate phoneme frequencies
      phoneme_frequencies = calculate_phoneme_frequencies(word_analyses)
      
      # Aggregate positional frequencies
      positional_frequencies = calculate_positional_frequencies(word_analyses)
      
      # Aggregate syllable count distribution
      syllable_count_distribution = calculate_syllable_count_distribution(word_analyses)
      
      # Aggregate syllable pattern distribution
      syllable_pattern_distribution = calculate_syllable_pattern_distribution(word_analyses)
      
      # Aggregate cluster patterns
      cluster_patterns = calculate_cluster_patterns(word_analyses)
      
      # Aggregate hiatus patterns
      hiatus_patterns = calculate_hiatus_patterns(word_analyses)
      
      # Aggregate vowel transitions
      vowel_transitions = calculate_vowel_transitions(word_analyses)
      
      # Aggregate complexity distribution
      complexity_distribution = calculate_complexity_distribution(word_analyses)
      
      # Calculate averages
      average_complexity = word_analyses.sum(&.complexity_score).to_f32 / word_analyses.size
      average_syllable_count = word_analyses.sum(&.syllable_count).to_f32 / word_analyses.size
      
      # Calculate consonant/vowel ratio
      total_consonants = word_analyses.sum(&.consonant_count)
      total_vowels = word_analyses.sum(&.vowel_count)
      consonant_vowel_ratio = total_vowels > 0 ? total_consonants.to_f32 / total_vowels.to_f32 : 0.0_f32
      
      # Generate recommendations
      recommended_budget = calculate_recommended_budget(average_complexity)
      recommended_templates = calculate_recommended_templates(syllable_pattern_distribution)
      recommended_hiatus_probability = calculate_recommended_hiatus_probability(hiatus_patterns, word_analyses)
      dominant_patterns = calculate_dominant_patterns(syllable_pattern_distribution)
      
      Analysis.new(
        phoneme_frequencies: phoneme_frequencies,
        positional_frequencies: positional_frequencies,
        syllable_count_distribution: syllable_count_distribution,
        syllable_pattern_distribution: syllable_pattern_distribution,
        cluster_patterns: cluster_patterns,
        hiatus_patterns: hiatus_patterns,
        complexity_distribution: complexity_distribution,
        average_complexity: average_complexity,
        average_syllable_count: average_syllable_count,
        consonant_vowel_ratio: consonant_vowel_ratio,
        recommended_budget: recommended_budget,
        recommended_templates: recommended_templates,
        recommended_hiatus_probability: recommended_hiatus_probability,
        dominant_patterns: dominant_patterns,
        vowel_transitions: vowel_transitions
      )
    end

    # Calculates phoneme frequencies across all words.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping phonemes to their relative frequencies
    private def calculate_phoneme_frequencies(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      phoneme_counts = Hash(String, Int32).new(0)
      total_phonemes = 0
      
      word_analyses.each do |analysis|
        analysis.phonemes.each do |phoneme|
          phoneme_counts[phoneme] += 1
          total_phonemes += 1
        end
      end
      
      frequencies = Hash(String, Float32).new
      phoneme_counts.each do |phoneme, count|
        frequencies[phoneme] = count.to_f32 / total_phonemes.to_f32
      end
      
      frequencies
    end

    # Calculates positional frequencies for each phoneme.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping phonemes to their positional frequency distributions
    private def calculate_positional_frequencies(word_analyses : Array(WordAnalysis)) : Hash(String, Hash(String, Float32))
      positional_counts = Hash(String, Hash(Symbol, Int32)).new { |h, k| h[k] = Hash(Symbol, Int32).new(0) }
      positional_totals = Hash(String, Int32).new(0)
      
      word_analyses.each do |analysis|
        analysis.phoneme_positions.each do |phoneme, positions|
          positions.each do |position|
            positional_counts[phoneme][position] += 1
            positional_totals[phoneme] += 1
          end
        end
      end
      
      # Convert to frequencies and stringify position keys
      frequencies = Hash(String, Hash(String, Float32)).new
      positional_counts.each do |phoneme, positions|
        total = positional_totals[phoneme]
        frequencies[phoneme] = Hash(String, Float32).new
        
        positions.each do |position, count|
          frequencies[phoneme][position.to_s] = count.to_f32 / total.to_f32
        end
      end
      
      frequencies
    end

    # Calculates syllable count distribution.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping syllable counts to their relative frequencies
    private def calculate_syllable_count_distribution(word_analyses : Array(WordAnalysis)) : Hash(Int32, Float32)
      count_frequencies = Hash(Int32, Int32).new(0)
      
      word_analyses.each do |analysis|
        count_frequencies[analysis.syllable_count] += 1
      end
      
      total_words = word_analyses.size
      distribution = Hash(Int32, Float32).new
      
      count_frequencies.each do |count, frequency|
        distribution[count] = frequency.to_f32 / total_words.to_f32
      end
      
      distribution
    end

    # Calculates syllable pattern distribution.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping syllable patterns to their relative frequencies
    private def calculate_syllable_pattern_distribution(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      pattern_counts = Hash(String, Int32).new(0)
      total_syllables = 0
      
      word_analyses.each do |analysis|
        analysis.syllable_patterns.each do |pattern|
          pattern_counts[pattern] += 1
          total_syllables += 1
        end
      end
      
      distribution = Hash(String, Float32).new
      pattern_counts.each do |pattern, count|
        distribution[pattern] = count.to_f32 / total_syllables.to_f32
      end
      
      distribution
    end

    # Calculates cluster pattern frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping cluster patterns to their relative frequencies
    private def calculate_cluster_patterns(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      cluster_counts = Hash(String, Int32).new(0)
      total_clusters = 0
      
      word_analyses.each do |analysis|
        analysis.clusters.each do |cluster|
          cluster_counts[cluster] += 1
          total_clusters += 1
        end
      end
      
      return Hash(String, Float32).new if total_clusters == 0
      
      patterns = Hash(String, Float32).new
      cluster_counts.each do |cluster, count|
        patterns[cluster] = count.to_f32 / total_clusters.to_f32
      end
      
      patterns
    end

    # Calculates hiatus pattern frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping hiatus patterns to their relative frequencies
    private def calculate_hiatus_patterns(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      hiatus_counts = Hash(String, Int32).new(0)
      total_hiatus = 0
      
      word_analyses.each do |analysis|
        analysis.hiatus_sequences.each do |hiatus|
          hiatus_counts[hiatus] += 1
          total_hiatus += 1
        end
      end
      
      return Hash(String, Float32).new if total_hiatus == 0
      
      patterns = Hash(String, Float32).new
      hiatus_counts.each do |hiatus, count|
        patterns[hiatus] = count.to_f32 / total_hiatus.to_f32
      end
      
      patterns
    end

    # Calculates complexity score distribution.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping complexity scores to their relative frequencies
    private def calculate_complexity_distribution(word_analyses : Array(WordAnalysis)) : Hash(Int32, Float32)
      complexity_counts = Hash(Int32, Int32).new(0)
      
      word_analyses.each do |analysis|
        complexity_counts[analysis.complexity_score] += 1
      end
      
      total_words = word_analyses.size
      distribution = Hash(Int32, Float32).new
      
      complexity_counts.each do |score, count|
        distribution[score] = count.to_f32 / total_words.to_f32
      end
      
      distribution
    end

    # Calculates the recommended complexity budget.
    #
    # ## Parameters
    # - `average_complexity`: Average complexity score
    #
    # ## Returns
    # Int32 representing the recommended budget
    private def calculate_recommended_budget(average_complexity : Float32) : Int32
      # Set budget slightly above average to allow for variation
      budget = (average_complexity * 1.2).round.to_i
      
      # Clamp to reasonable bounds
      [3, [budget, 15].min].max
    end

    # Calculates recommended syllable templates.
    #
    # ## Parameters
    # - `pattern_distribution`: Hash mapping patterns to frequencies
    #
    # ## Returns
    # Array of recommended template patterns
    private def calculate_recommended_templates(pattern_distribution : Hash(String, Float32)) : Array(String)
      # Select patterns that appear frequently (> 10% of syllables)
      frequent_patterns = pattern_distribution.select { |_, freq| freq > 0.1 }
      
      # Sort by frequency and take top patterns
      templates = frequent_patterns.to_a
        .sort_by { |_, freq| -freq }
        .first(5)
        .map { |pattern, _| pattern }
      
      # Ensure we have at least basic patterns
      templates << "CV" unless templates.includes?("CV")
      templates << "CVC" unless templates.includes?("CVC")
      
      templates.uniq
    end

    # Calculates recommended hiatus probability.
    #
    # ## Parameters
    # - `hiatus_patterns`: Hash mapping hiatus patterns to frequencies
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Float32 representing the recommended hiatus probability
    private def calculate_recommended_hiatus_probability(hiatus_patterns : Hash(String, Float32), word_analyses : Array(WordAnalysis)) : Float32
      total_words = word_analyses.size
      words_with_hiatus = word_analyses.count(&.has_hiatus?)
      
      # Base probability on how many words contain hiatus
      base_probability = words_with_hiatus.to_f32 / total_words.to_f32
      
      # Adjust based on hiatus frequency
      if hiatus_patterns.size > 0
        # If there are many different hiatus patterns, increase probability
        pattern_diversity = hiatus_patterns.size.to_f32 / 10.0_f32
        base_probability += pattern_diversity * 0.1
      end
      
      # Clamp to reasonable bounds
      [0.0_f32, [base_probability, 0.8_f32].min].max
    end

    # Calculates vowel transition patterns.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping vowels to their transition frequencies
    private def calculate_vowel_transitions(word_analyses : Array(WordAnalysis)) : Hash(String, Hash(String, Float32))
      transition_counts = Hash(String, Hash(String, Int32)).new { |h, k| h[k] = Hash(String, Int32).new(0) }
      transition_totals = Hash(String, Int32).new(0)
      
      word_analyses.each do |analysis|
        vowels = analysis.phonemes.select { |p| is_vowel?(p) }
        
        # Track transitions between adjacent vowels
        (0...vowels.size-1).each do |i|
          from_vowel = vowels[i]
          to_vowel = vowels[i+1]
          
          transition_counts[from_vowel][to_vowel] += 1
          transition_totals[from_vowel] += 1
        end
      end
      
      # Convert counts to frequencies
      transitions = Hash(String, Hash(String, Float32)).new
      transition_counts.each do |from_vowel, to_vowels|
        total = transition_totals[from_vowel]
        next if total == 0
        
        transitions[from_vowel] = Hash(String, Float32).new
        to_vowels.each do |to_vowel, count|
          transitions[from_vowel][to_vowel] = count.to_f32 / total.to_f32
        end
      end
      
      transitions
    end

    # Checks if a phoneme is a vowel (helper method).
    #
    # ## Parameters
    # - `phoneme`: The phoneme to check
    #
    # ## Returns
    # `true` if the phoneme is a vowel, `false` otherwise
    private def is_vowel?(phoneme : String) : Bool
      ["a", "e", "i", "o", "u", "y", "ɑ", "ɛ", "ɪ", "ɔ", "ʊ", "ə", "æ", "ʌ", "ɒ"].includes?(phoneme)
    end

    # Calculates the dominant syllable patterns.
    #
    # ## Parameters
    # - `pattern_distribution`: Hash mapping patterns to frequencies
    #
    # ## Returns
    # Array of dominant pattern strings
    private def calculate_dominant_patterns(pattern_distribution : Hash(String, Float32)) : Array(String)
      pattern_distribution.to_a
        .sort_by { |_, freq| -freq }
        .first(3)
        .map { |pattern, _| pattern }
    end
  end
end