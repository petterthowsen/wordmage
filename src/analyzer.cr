require "./word_analyzer"
require "./analysis"
require "./syllable_template"

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
  # 
  # # Basic analysis
  # analysis = analyzer.analyze(words)
  # 
  # # Analysis with Gusein-Zade smoothing
  # analysis = analyzer.analyze(words, use_gusein_zade_smoothing: true, smoothing_factor: 0.3)
  # 
  # # Analysis with templates
  # analysis = analyzer.with_templates(templates).analyze(words)
  # 
  # # Analysis with both templates and Gusein-Zade smoothing
  # analysis = analyzer.with_templates(templates).analyze(words, true, 0.3)
  # ```
  class Analyzer
    @word_analyzer : WordAnalyzer
    @syllable_templates : Array(SyllableTemplate)?

    # Creates a new Analyzer.
    #
    # ## Parameters
    # - `romanization_map`: RomanizationMap for converting romanized text to phonemes
    def initialize(@romanization_map : RomanizationMap)
      @word_analyzer = WordAnalyzer.new(@romanization_map)
      @syllable_templates = nil
    end

    # Configures the analyzer to use specific syllable templates.
    #
    # This method allows users to provide their own SyllableTemplate objects
    # with defined onset and coda clusters. The analysis will respect these
    # templates while still detecting all other phonological patterns.
    #
    # ## Parameters
    # - `templates`: Array of SyllableTemplate objects to use for analysis
    #
    # ## Returns
    # Self (for method chaining)
    #
    # ## Example
    # ```crystal
    # templates = [
    #   SyllableTemplate.new("CV", allowed_clusters: ["br", "tr"]),
    #   SyllableTemplate.new("CVC", allowed_coda_clusters: ["st", "nt"])
    # ]
    # analysis = analyzer.with_templates(templates).analyze(words)
    # ```
    def with_templates(templates : Array(SyllableTemplate)) : self
      @syllable_templates = templates
      self
    end

    # Analyzes a set of words to extract aggregate patterns.
    #
    # ## Parameters
    # - `words`: Array of romanized words to analyze
    # - `use_gusein_zade_smoothing`: Whether to apply Gusein-Zade smoothing (default: false)
    # - `smoothing_factor`: Weight of Gusein-Zade vs empirical (0.0-1.0, default: 0.3)
    #
    # ## Returns
    # Analysis containing aggregate statistics and recommendations
    #
    # ## Example
    # ```crystal
    # # Basic analysis
    # analysis = analyzer.analyze(["nazagon", "thadrae", "drayeki"])
    # 
    # # Analysis with Gusein-Zade smoothing
    # analysis = analyzer.analyze(words, true, 0.4)
    # 
    # # Analysis with templates
    # analysis = analyzer.with_templates(templates).analyze(words)
    # 
    # # Analysis with both templates and Gusein-Zade smoothing
    # analysis = analyzer.with_templates(templates).analyze(words, true, 0.3)
    # ```
    def analyze(words : Array(String), use_gusein_zade_smoothing : Bool = false, smoothing_factor : Float32 = 0.3_f32) : Analysis
      return Analysis.new(provided_templates: @syllable_templates) if words.empty?
      
      # Analyze each word individually (with templates if provided)
      word_analyses = if templates = @syllable_templates
        words.map { |word| @word_analyzer.analyze(word, templates) }
      else
        words.map { |word| @word_analyzer.analyze(word) }
      end
      
      # Aggregate phoneme frequencies (with optional Gusein-Zade smoothing)
      phoneme_frequencies = use_gusein_zade_smoothing ? 
        calculate_gusein_zade_smoothed_frequencies(word_analyses, smoothing_factor) :
        calculate_phoneme_frequencies(word_analyses)
      
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
      
      # Aggregate gemination patterns
      gemination_patterns = calculate_gemination_patterns(word_analyses)
      
      # Aggregate vowel lengthening patterns
      vowel_lengthening_patterns = calculate_vowel_lengthening_patterns(word_analyses)
      
      # Aggregate phoneme transitions
      phoneme_transitions = calculate_phoneme_transitions(word_analyses)
      
      # Aggregate bigram and trigram frequencies
      bigram_frequencies = calculate_bigram_frequencies(word_analyses)
      trigram_frequencies = calculate_trigram_frequencies(word_analyses)
      
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
      
      # Handle templates vs patterns
      if templates = @syllable_templates
        recommended_templates = templates.map(&.pattern)
        recommended_hiatus_probability = calculate_hiatus_probability_from_templates(templates)
      else
        recommended_templates = calculate_recommended_templates(syllable_pattern_distribution)
        recommended_hiatus_probability = calculate_recommended_hiatus_probability(hiatus_patterns, word_analyses)
      end
      
      recommended_gemination_probability = calculate_recommended_gemination_probability(gemination_patterns, word_analyses)
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
        recommended_gemination_probability: recommended_gemination_probability,
        dominant_patterns: dominant_patterns,
        vowel_transitions: vowel_transitions,
        gemination_patterns: gemination_patterns,
        vowel_lengthening_patterns: vowel_lengthening_patterns,
        phoneme_transitions: phoneme_transitions,
        bigram_frequencies: bigram_frequencies,
        trigram_frequencies: trigram_frequencies,
        provided_templates: @syllable_templates
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

    # Calculates Gusein-Zade smoothed phoneme frequencies.
    #
    # This method combines empirical frequencies with theoretical Gusein-Zade
    # distribution to create more naturalistic frequency patterns.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    # - `smoothing_factor`: Weight of Gusein-Zade vs empirical (0.0-1.0, default: 0.3)
    #
    # ## Returns
    # Hash mapping phonemes to their smoothed frequencies
    private def calculate_gusein_zade_smoothed_frequencies(word_analyses : Array(WordAnalysis), smoothing_factor : Float32 = 0.3_f32) : Hash(String, Float32)
      # First get empirical frequencies
      empirical_frequencies = calculate_phoneme_frequencies(word_analyses)
      return empirical_frequencies if empirical_frequencies.empty?
      
      # Sort phonemes by empirical frequency (highest first)
      sorted_phonemes = empirical_frequencies.to_a
        .sort_by { |_, freq| -freq }
        .map { |phoneme, _| phoneme }
      
      n = sorted_phonemes.size
      
      # Calculate raw Gusein-Zade weights
      raw_weights = [] of Float32
      (1..n).each do |r|
        weight = Math.log(n + 1) - Math.log(r)
        raw_weights << weight.to_f32
      end
      
      # Normalize Gusein-Zade weights to sum to 1.0
      total_weight = raw_weights.sum
      return empirical_frequencies if total_weight <= 0
      
      gusein_zade_weights = Hash(String, Float32).new
      sorted_phonemes.each_with_index do |phoneme, i|
        gusein_zade_weights[phoneme] = raw_weights[i] / total_weight
      end
      
      # Combine empirical and theoretical frequencies
      smoothed = Hash(String, Float32).new
      smoothing_factor = [[smoothing_factor, 0.0_f32].max, 1.0_f32].min
      
      empirical_frequencies.each do |phoneme, empirical_freq|
        gusein_zade_weight = gusein_zade_weights[phoneme]? || 0.0_f32
        smoothed[phoneme] = (1.0_f32 - smoothing_factor) * empirical_freq + 
                           smoothing_factor * gusein_zade_weight
      end
      
      # Normalize to ensure sum is 1.0
      total = smoothed.values.sum
      if total > 0
        smoothed.each { |k, v| smoothed[k] = v / total }
      end
      
      smoothed
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
        analysis.phoneme_positions.each do |position, phonemes|
          phonemes.each do |phoneme|
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

    # Calculates gemination pattern frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping gemination patterns to their relative frequencies
    private def calculate_gemination_patterns(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      gemination_counts = Hash(String, Int32).new(0)
      total_geminations = 0
      
      word_analyses.each do |analysis|
        analysis.gemination_sequences.each do |gemination|
          gemination_counts[gemination] += 1
          total_geminations += 1
        end
      end
      
      return Hash(String, Float32).new if total_geminations == 0
      
      patterns = Hash(String, Float32).new
      gemination_counts.each do |gemination, count|
        patterns[gemination] = count.to_f32 / total_geminations.to_f32
      end
      
      patterns
    end

    # Calculates vowel lengthening pattern frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping vowel lengthening patterns to their relative frequencies
    private def calculate_vowel_lengthening_patterns(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      lengthening_counts = Hash(String, Int32).new(0)
      total_lengthenings = 0
      
      word_analyses.each do |analysis|
        analysis.vowel_lengthening_sequences.each do |lengthening|
          lengthening_counts[lengthening] += 1
          total_lengthenings += 1
        end
      end
      
      return Hash(String, Float32).new if total_lengthenings == 0
      
      patterns = Hash(String, Float32).new
      lengthening_counts.each do |lengthening, count|
        patterns[lengthening] = count.to_f32 / total_lengthenings.to_f32
      end
      
      patterns
    end

    # Calculates phoneme transition frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping phonemes to their transition frequencies
    private def calculate_phoneme_transitions(word_analyses : Array(WordAnalysis)) : Hash(String, Hash(String, Float32))
      transition_counts = Hash(String, Hash(String, Int32)).new { |h, k| h[k] = Hash(String, Int32).new(0) }
      transition_totals = Hash(String, Int32).new(0)
      
      word_analyses.each do |analysis|
        analysis.phoneme_transitions.each do |from_phoneme, to_phoneme|
          transition_counts[from_phoneme][to_phoneme] += 1
          transition_totals[from_phoneme] += 1
        end
      end
      
      # Convert counts to frequencies
      transitions = Hash(String, Hash(String, Float32)).new
      transition_counts.each do |from_phoneme, to_phonemes|
        total = transition_totals[from_phoneme]
        next if total == 0
        
        transitions[from_phoneme] = Hash(String, Float32).new
        to_phonemes.each do |to_phoneme, count|
          transitions[from_phoneme][to_phoneme] = count.to_f32 / total.to_f32
        end
      end
      
      transitions
    end

    # Calculates bigram frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping bigrams to their relative frequencies
    private def calculate_bigram_frequencies(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      bigram_counts = Hash(String, Int32).new(0)
      total_bigrams = 0
      
      word_analyses.each do |analysis|
        analysis.bigrams.each do |bigram|
          bigram_counts[bigram] += 1
          total_bigrams += 1
        end
      end
      
      return Hash(String, Float32).new if total_bigrams == 0
      
      frequencies = Hash(String, Float32).new
      bigram_counts.each do |bigram, count|
        frequencies[bigram] = count.to_f32 / total_bigrams.to_f32
      end
      
      frequencies
    end

    # Calculates trigram frequencies.
    #
    # ## Parameters
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Hash mapping trigrams to their relative frequencies
    private def calculate_trigram_frequencies(word_analyses : Array(WordAnalysis)) : Hash(String, Float32)
      trigram_counts = Hash(String, Int32).new(0)
      total_trigrams = 0
      
      word_analyses.each do |analysis|
        analysis.trigrams.each do |trigram|
          trigram_counts[trigram] += 1
          total_trigrams += 1
        end
      end
      
      return Hash(String, Float32).new if total_trigrams == 0
      
      frequencies = Hash(String, Float32).new
      trigram_counts.each do |trigram, count|
        frequencies[trigram] = count.to_f32 / total_trigrams.to_f32
      end
      
      frequencies
    end

    # Calculates recommended gemination probability.
    #
    # ## Parameters
    # - `gemination_patterns`: Hash mapping gemination patterns to frequencies
    # - `word_analyses`: Array of WordAnalysis instances
    #
    # ## Returns
    # Float32 representing the recommended gemination probability
    private def calculate_recommended_gemination_probability(gemination_patterns : Hash(String, Float32), word_analyses : Array(WordAnalysis)) : Float32
      total_words = word_analyses.size
      words_with_gemination = word_analyses.count(&.has_gemination?)
      
      # Base probability on how many words contain gemination
      base_probability = words_with_gemination.to_f32 / total_words.to_f32
      
      # Adjust based on gemination frequency
      if gemination_patterns.size > 0
        # If there are many different gemination patterns, increase probability
        pattern_diversity = gemination_patterns.size.to_f32 / 5.0_f32
        base_probability += pattern_diversity * 0.1
      end
      
      # Clamp to reasonable bounds
      [0.0_f32, [base_probability, 0.8_f32].min].max
    end

    # Calculates hiatus probability from provided SyllableTemplate objects.
    #
    # ## Parameters
    # - `syllable_templates`: Array of SyllableTemplate objects
    #
    # ## Returns
    # Float32 representing the average hiatus probability across templates
    private def calculate_hiatus_probability_from_templates(syllable_templates : Array(SyllableTemplate)) : Float32
      return 0.0_f32 if syllable_templates.empty?
      
      # Calculate weighted average of hiatus probabilities
      total_probability = 0.0_f32
      total_weight = 0.0_f32
      
      syllable_templates.each do |template|
        weight = template.probability
        total_probability += template.hiatus_probability * weight
        total_weight += weight
      end
      
      total_weight > 0 ? total_probability / total_weight : 0.0_f32
    end
  end
end