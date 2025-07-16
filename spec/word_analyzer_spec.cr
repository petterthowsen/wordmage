require "./spec_helper"

describe WordMage::WordAnalyzer do
  describe "#initialize" do
    it "creates an analyzer with romanization map" do
      romanization = WordMage::RomanizationMap.new({"t" => "t", "a" => "a", "n" => "n"})
      analyzer = WordMage::WordAnalyzer.new(romanization)
      analyzer.should be_a(WordMage::WordAnalyzer)
    end
  end

  describe "#analyze" do
    it "analyzes basic word structure" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tanoke")
      
      analysis.syllable_count.should eq(3)
      analysis.consonant_count.should eq(3)  # t, n, k
      analysis.vowel_count.should eq(3)      # a, o, e
      analysis.complexity_score.should be > 0
      analysis.phonemes.should eq(["t", "a", "n", "o", "k", "e"])
    end

    it "detects consonant clusters" do
      romanization = WordMage::RomanizationMap.new({
        "s" => "s", "p" => "p", "r" => "r", "t" => "t",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("spraeto")
      
      analysis.cluster_count.should be >= 1
      analysis.clusters.should contain("spr")
      analysis.syllable_count.should eq(3)  # spr-ae-to
    end

    it "detects vowel sequences (hiatus)" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "r" => "r", "n" => "n",
        "a" => "a", "e" => "e", "o" => "o", "i" => "i"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("taeron")
      
      analysis.hiatus_count.should be >= 1
      analysis.hiatus_sequences.should contain("ae")
      analysis.syllable_count.should eq(3)  # ta-e-ron
    end

    it "detects gemination (consonant doubling)" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k",
        "a" => "a", "e" => "e"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tanneka")
      
      analysis.gemination_sequences.size.should be >= 1
      analysis.gemination_sequences.should contain("nn")
      analysis.syllable_count.should eq(3)  # tan-ne-ka
    end

    it "detects vowel lengthening (vowel doubling)" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("taanoke")
      
      analysis.vowel_lengthening_sequences.size.should be >= 1
      analysis.vowel_lengthening_sequences.should contain("aa")
      analysis.syllable_count.should eq(3)  # taa-no-ke
    end

    it "calculates complexity scores correctly" do
      romanization = WordMage::RomanizationMap.new({
        "s" => "s", "p" => "p", "r" => "r", "t" => "t", "n" => "n",
        "a" => "a", "e" => "e", "o" => "o", "i" => "i"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      # Simple word should have low complexity
      simple_analysis = analyzer.analyze("tane")
      
      # Complex word with clusters and hiatus should have higher complexity
      complex_analysis = analyzer.analyze("spraenot")
      
      complex_analysis.complexity_score.should be > simple_analysis.complexity_score
    end

    it "analyzes phoneme positions correctly" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tane")
      
      analysis.phoneme_positions.has_key?(:initial).should be_true
      analysis.phoneme_positions.has_key?(:final).should be_true
      analysis.phoneme_positions[:initial].should contain("t")
      analysis.phoneme_positions[:final].should contain("e")
    end

    it "handles single syllable words" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "a" => "a", "k" => "k"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tak")
      
      analysis.syllable_count.should eq(1)
      analysis.consonant_count.should eq(2)
      analysis.vowel_count.should eq(1)
      analysis.clusters.should be_empty  # No clusters in CVC
      analysis.hiatus_sequences.should be_empty
    end

    it "handles complex multilingual phoneme mappings" do
      romanization = WordMage::RomanizationMap.new({
        "θ" => "th", "tʃ" => "ch", "ʃ" => "sh",
        "ɑ" => "a", "ɛ" => "e", "ɔ" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("thacho")
      
      analysis.phonemes.should eq(["θ", "ɑ", "tʃ", "ɔ"])
      analysis.syllable_count.should eq(2)  # θɑ-tʃɔ
      analysis.consonant_count.should eq(2)  # θ, tʃ
      analysis.vowel_count.should eq(2)      # ɑ, ɔ
    end
  end

  describe "syllable pattern detection" do
    it "identifies CV syllable patterns" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tanoke")
      
      analysis.syllable_patterns.should eq(["CV", "CV", "CV"])
    end

    it "identifies CVC syllable patterns" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r",
        "a" => "a", "e" => "e"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("tanker")
      
      analysis.syllable_patterns.should contain("CVC")
    end

    it "identifies CCV syllable patterns" do
      romanization = WordMage::RomanizationMap.new({
        "s" => "s", "p" => "p", "r" => "r", "t" => "t",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("ospra")
      
      analysis.syllable_patterns.should contain("CCV")
    end
  end

  describe "error handling" do
    it "handles unknown romanization gracefully" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      # Should not crash on unknown characters
      analysis = analyzer.analyze("xyz")
      analysis.should be_a(WordMage::WordAnalysis)
    end

    it "handles empty words" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      analysis = analyzer.analyze("")
      analysis.syllable_count.should eq(0)
      analysis.consonant_count.should eq(0)
      analysis.vowel_count.should eq(0)
    end
  end

  describe "#analyze with SyllableTemplate" do
    it "analyzes word with provided templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV", allowed_clusters: ["tr"]),
        WordMage::SyllableTemplate.new("CVC", allowed_coda_clusters: ["nt"])
      ]
      
      analysis = analyzer.analyze("tanoke", templates)
      
      analysis.syllable_count.should eq(3)
      analysis.consonant_count.should eq(3)
      analysis.vowel_count.should eq(3)
      analysis.should be_a(WordMage::WordAnalysis)
    end

    it "produces same results as standard analyze method" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::WordAnalyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      
      word = "tanoke"
      standard_analysis = analyzer.analyze(word)
      template_analysis = analyzer.analyze(word, templates)
      
      template_analysis.syllable_count.should eq(standard_analysis.syllable_count)
      template_analysis.consonant_count.should eq(standard_analysis.consonant_count)
      template_analysis.vowel_count.should eq(standard_analysis.vowel_count)
      template_analysis.phonemes.should eq(standard_analysis.phonemes)
      template_analysis.syllable_patterns.should eq(standard_analysis.syllable_patterns)
    end
  end
end

describe WordMage::Analyzer do
  describe "#initialize" do
    it "creates an aggregate analyzer with romanization map" do
      romanization = WordMage::RomanizationMap.new({"t" => "t", "a" => "a"})
      analyzer = WordMage::Analyzer.new(romanization)
      analyzer.should be_a(WordMage::Analyzer)
    end
  end

  describe "#analyze" do
    it "analyzes multiple words and provides aggregate statistics" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tanoke", "srekon", "tarase"]
      analysis = analyzer.analyze(words)
      
      analysis.average_syllable_count.should be > 0
      analysis.average_complexity.should be > 0
      analysis.phoneme_frequencies.has_key?("t").should be_true
      analysis.syllable_pattern_distribution.has_key?("CV").should be_true
    end

    it "detects gemination patterns across word collection" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tannok", "kesso", "normal"]
      analysis = analyzer.analyze(words)
      
      analysis.gemination_patterns.has_key?("nn").should be_true
      analysis.gemination_patterns.has_key?("ss").should be_true
      analysis.gemination_patterns["nn"].should be > 0
    end

    it "detects vowel lengthening patterns across word collection" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["taanok", "keeto", "normal"]
      analysis = analyzer.analyze(words)
      
      analysis.vowel_lengthening_patterns.has_key?("aa").should be_true
      analysis.vowel_lengthening_patterns.has_key?("ee").should be_true
      analysis.vowel_lengthening_patterns["aa"].should be > 0
    end

    it "calculates cluster frequency statistics" do
      romanization = WordMage::RomanizationMap.new({
        "s" => "s", "p" => "p", "r" => "r", "t" => "t", "n" => "n",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["spraeto", "strano", "tanoke"]
      analysis = analyzer.analyze(words)
      
      analysis.cluster_patterns.has_key?("spr").should be_true
      analysis.cluster_patterns.has_key?("str").should be_true
      analysis.cluster_patterns["spr"].should be > 0
    end

    it "provides recommendations based on analysis" do
      romanization = WordMage::RomanizationMap.new({
        "s" => "s", "p" => "p", "r" => "r", "t" => "t", "n" => "n",
        "a" => "a", "e" => "e", "o" => "o", "i" => "i"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Complex words should suggest higher budget
      complex_words = ["spraenoti", "stronaeki", "spraitosen"]
      analysis = analyzer.analyze(complex_words)
      
      analysis.recommended_budget.should be > 5
      analysis.dominant_patterns.should_not be_empty
      analysis.recommended_templates.should_not be_empty
    end

    it "handles empty word collections" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::Analyzer.new(romanization)
      
      analysis = analyzer.analyze([] of String)
      
      analysis.average_syllable_count.should eq(0.0)
      analysis.phoneme_frequencies.should be_empty
    end

    it "provides statistical insights for language modeling" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o", "i" => "i"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Simulate a consistent conlang word set
      words = ["tanoke", "sorina", "ketano", "nisora", "rotane"]
      analysis = analyzer.analyze(words)
      
      # Should detect patterns useful for generation
      analysis.syllable_count_distribution.should_not be_empty
      analysis.positional_frequencies.has_key?("t").should be_true
      analysis.vowel_transitions.should_not be_empty
    end
  end

  describe "#analyze with SyllableTemplate" do
    it "analyzes words with provided templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV", allowed_clusters: ["tr"]),
        WordMage::SyllableTemplate.new("CVC", allowed_coda_clusters: ["nt", "st"])
      ]
      
      words = ["tanoke", "srekon", "tarase"]
      analysis = analyzer.with_templates(templates).analyze(words)
      
      analysis.average_syllable_count.should be > 0
      analysis.average_complexity.should be > 0
      analysis.phoneme_frequencies.has_key?("t").should be_true
      analysis.syllable_pattern_distribution.has_key?("CV").should be_true
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.size.should eq(2)
    end

    it "uses provided templates for recommendations" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.3_f32),
        WordMage::SyllableTemplate.new("CVC", hiatus_probability: 0.1_f32)
      ]
      
      words = ["tanoke", "kon", "tara"]
      analysis = analyzer.with_templates(templates).analyze(words)
      
      # Should use provided template patterns instead of generating new ones
      analysis.recommended_templates.should eq(["CV", "CVC"])
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.map(&.pattern).should eq(["CV", "CVC"])
    end

    it "calculates hiatus probability from provided templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.4_f32, probability: 1.0_f32),
        WordMage::SyllableTemplate.new("CVC", hiatus_probability: 0.2_f32, probability: 1.0_f32)
      ]
      
      words = ["tanoke", "kon", "tara"]
      analysis = analyzer.with_templates(templates).analyze(words)
      
      # Should calculate weighted average: (0.4 * 1.0 + 0.2 * 1.0) / (1.0 + 1.0) = 0.3
      analysis.recommended_hiatus_probability.should be_close(0.3_f32, 0.01_f32)
    end

    it "preserves all other analysis features with templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      
      words = ["tannok", "keeto", "spraeto"]
      analysis = analyzer.with_templates(templates).analyze(words)
      
      # Should still detect gemination and other patterns
      analysis.gemination_patterns.should_not be_empty
      analysis.vowel_lengthening_patterns.should_not be_empty
      analysis.cluster_patterns.should_not be_empty
      analysis.phoneme_transitions.should_not be_empty
      analysis.bigram_frequencies.should_not be_empty
      analysis.dominant_patterns.should_not be_empty
    end

    it "handles empty word collections with templates" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      
      analysis = analyzer.with_templates(templates).analyze([] of String)
      
      analysis.average_syllable_count.should eq(0.0)
      analysis.phoneme_frequencies.should be_empty
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.size.should eq(2)
    end
  end

  describe "#analyze with Gusein-Zade parameters" do
    it "applies Gusein-Zade smoothing to phoneme frequencies" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o", "i" => "i"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Use words with clear frequency patterns
      words = ["tttaaa", "ttaa", "ta", "n", "nk"]  # t=6, a=6, n=2, k=1
      
      # Get both regular and Gusein-Zade smoothed analysis
      regular_analysis = analyzer.analyze(words)
      smoothed_analysis = analyzer.analyze(words, true, 0.5_f32)
      
      # Both should have same phonemes but different frequencies
      regular_analysis.phoneme_frequencies.keys.sort.should eq(smoothed_analysis.phoneme_frequencies.keys.sort)
      
      # Frequencies should be different due to smoothing
      regular_analysis.phoneme_frequencies.should_not eq(smoothed_analysis.phoneme_frequencies)
      
      # Smoothed frequencies should still sum to 1.0
      smoothed_analysis.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
    end

    it "handles different smoothing factors" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]
      
      # Test different smoothing factors
      light_smoothing = analyzer.analyze(words, true, 0.1_f32)
      heavy_smoothing = analyzer.analyze(words, true, 0.9_f32)
      
      # Both should have same phonemes
      light_smoothing.phoneme_frequencies.keys.sort.should eq(heavy_smoothing.phoneme_frequencies.keys.sort)
      
      # But different frequency distributions
      light_smoothing.phoneme_frequencies.should_not eq(heavy_smoothing.phoneme_frequencies)
      
      # Both should sum to 1.0
      light_smoothing.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
      heavy_smoothing.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
    end

    it "preserves all other analysis features with Gusein-Zade smoothing" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tannok", "keeto", "spraeto"]
      
      regular_analysis = analyzer.analyze(words)
      smoothed_analysis = analyzer.analyze(words, true, 0.3_f32)
      
      # Non-frequency features should be identical
      regular_analysis.syllable_count_distribution.should eq(smoothed_analysis.syllable_count_distribution)
      regular_analysis.syllable_pattern_distribution.should eq(smoothed_analysis.syllable_pattern_distribution)
      regular_analysis.cluster_patterns.should eq(smoothed_analysis.cluster_patterns)
      regular_analysis.gemination_patterns.should eq(smoothed_analysis.gemination_patterns)
      regular_analysis.average_complexity.should eq(smoothed_analysis.average_complexity)
      regular_analysis.average_syllable_count.should eq(smoothed_analysis.average_syllable_count)
      
      # Only phoneme frequencies should differ
      regular_analysis.phoneme_frequencies.should_not eq(smoothed_analysis.phoneme_frequencies)
    end

    it "handles edge cases with smoothing" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Test with empty words
      empty_analysis = analyzer.analyze([] of String, true, 0.5_f32)
      empty_analysis.phoneme_frequencies.should be_empty
      
      # Test with single phoneme
      single_analysis = analyzer.analyze(["a"], true, 0.5_f32)
      single_analysis.phoneme_frequencies.has_key?("a").should be_true
      single_analysis.phoneme_frequencies["a"].should be_close(1.0_f32, 0.001_f32)
    end

    it "clamps smoothing factor to valid range" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tane", "neat"]
      
      # Test with out-of-range smoothing factors
      negative_smoothing = analyzer.analyze(words, true, -0.5_f32)
      over_smoothing = analyzer.analyze(words, true, 1.5_f32)
      
      # Should still produce valid results
      negative_smoothing.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
      over_smoothing.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
    end
  end

  describe "Gusein-Zade Analysis methods" do
    it "calculates Gusein-Zade weights correctly" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Create analysis with known frequency pattern
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]  # t=6, a=6, n=1, e=1, k=1
      analysis = analyzer.analyze(words)
      
      # Get Gusein-Zade weights
      weights = analysis.gusein_zade_weights
      
      # Should have weights for all phonemes
      weights.keys.sort.should eq(["a", "e", "k", "n", "t"])
      
      # Weights should sum to 1.0
      weights.values.sum.should be_close(1.0_f32, 0.001_f32)
      
      # Most frequent phonemes should have higher weights
      # (t and a are tied for most frequent empirically)
      weights["t"].should be > weights["k"]
      weights["a"].should be > weights["k"]
    end

    it "generates smoothed phoneme frequencies" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]
      analysis = analyzer.analyze(words)
      
      # Get smoothed frequencies
      smoothed = analysis.smoothed_phoneme_frequencies(0.3_f32)
      
      # Should have same phonemes
      smoothed.keys.sort.should eq(analysis.phoneme_frequencies.keys.sort)
      
      # Should sum to 1.0
      smoothed.values.sum.should be_close(1.0_f32, 0.001_f32)
      
      # Should be different from original
      smoothed.should_not eq(analysis.phoneme_frequencies)
    end

    it "ranks phonemes by frequency" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]  # t=6, a=6, n=1, e=1, k=1
      analysis = analyzer.analyze(words)
      
      # Get frequency ranking
      ranking = analysis.phoneme_frequency_ranking
      
      # Should include all phonemes
      ranking.size.should eq(5)
      
      # Most frequent should be first (t and a tie at 6/15 = 0.4)
      (ranking[0] == "t" || ranking[0] == "a").should be_true
      (ranking[1] == "t" || ranking[1] == "a").should be_true
      
      # Least frequent should be last
      (ranking[-1] == "n" || ranking[-1] == "e" || ranking[-1] == "k").should be_true
    end

    it "calculates phoneme ranks correctly" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]  # t=6, a=6, n=1, e=1, k=1
      analysis = analyzer.analyze(words)
      
      # Get ranks
      t_rank = analysis.phoneme_rank("t")
      a_rank = analysis.phoneme_rank("a")
      k_rank = analysis.phoneme_rank("k")
      missing_rank = analysis.phoneme_rank("x")
      
      # t and a should be rank 1 or 2 (tied for first)
      (t_rank == 1 || t_rank == 2).should be_true
      (a_rank == 1 || a_rank == 2).should be_true
      
      # k should be rank 3, 4, or 5 (tied for last)
      (k_rank == 3 || k_rank == 4 || k_rank == 5).should be_true
      
      # Missing phoneme should return 0
      missing_rank.should eq(0)
    end

    it "compares empirical vs Gusein-Zade frequencies" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tttaaa", "ttaa", "ta", "ne", "k"]
      analysis = analyzer.analyze(words)
      
      # Get deviation metrics
      deviation = analysis.gusein_zade_deviation
      
      # Should have required metrics
      deviation.has_key?("mse").should be_true
      deviation.has_key?("rmse").should be_true
      deviation.has_key?("correlation").should be_true
      
      # MSE should be non-negative
      deviation["mse"].should be >= 0
      
      # RMSE should be square root of MSE
      deviation["rmse"].should be_close(Math.sqrt(deviation["mse"]), 0.001_f32)
      
      # Correlation should be between -1 and 1
      deviation["correlation"].should be >= -1.0_f32
      deviation["correlation"].should be <= 1.0_f32
    end

    it "handles edge cases in Gusein-Zade calculations" do
      romanization = WordMage::RomanizationMap.new({"a" => "a"})
      analyzer = WordMage::Analyzer.new(romanization)
      
      # Test with empty analysis
      empty_analysis = analyzer.analyze([] of String)
      empty_weights = empty_analysis.gusein_zade_weights
      empty_weights.should be_empty
      
      # Test with single phoneme
      single_analysis = analyzer.analyze(["a"])
      single_weights = single_analysis.gusein_zade_weights
      single_weights.has_key?("a").should be_true
      single_weights["a"].should be_close(1.0_f32, 0.001_f32)
    end
  end

  describe "Chainable API" do
    it "supports method chaining with templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s",
        "a" => "a", "e" => "e", "o" => "o"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      
      words = ["tanoke", "kon", "tara"]
      
      # Test method chaining
      analysis = analyzer.with_templates(templates).analyze(words)
      
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.size.should eq(2)
      analysis.recommended_templates.should eq(["CV", "CVC"])
    end

    it "supports chaining with templates and Gusein-Zade parameters" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      
      words = ["tanake", "tekna", "kaneta"]
      
      # Test chaining with both templates and Gusein-Zade
      analysis = analyzer.with_templates(templates).analyze(words, true, 0.4_f32)
      
      # Should have templates
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.size.should eq(2)
      
      # Should have smoothed frequencies
      analysis.phoneme_frequencies.should_not be_empty
      analysis.phoneme_frequencies.values.sum.should be_close(1.0_f32, 0.001_f32)
    end

    it "allows reusing analyzer with different templates" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates1 = [WordMage::SyllableTemplate.new("CV")]
      templates2 = [WordMage::SyllableTemplate.new("CVC")]
      
      words = ["tanake", "tekna"]
      
      # Use different templates with same analyzer
      analysis1 = analyzer.with_templates(templates1).analyze(words)
      analysis2 = analyzer.with_templates(templates2).analyze(words)
      
      analysis1.recommended_templates.should eq(["CV"])
      analysis2.recommended_templates.should eq(["CVC"])
      
      # Should be different analyses
      analysis1.provided_templates.not_nil!.size.should eq(1)
      analysis2.provided_templates.not_nil!.size.should eq(1)
    end

    it "works without templates for regular analysis" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      words = ["tanake", "tekna"]
      
      # Regular analysis without templates
      analysis = analyzer.analyze(words)
      
      analysis.provided_templates.should be_nil
      analysis.recommended_templates.should_not be_empty
      analysis.phoneme_frequencies.should_not be_empty
    end

    it "preserves analyzer state between calls" do
      romanization = WordMage::RomanizationMap.new({
        "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
      })
      analyzer = WordMage::Analyzer.new(romanization)
      
      templates = [WordMage::SyllableTemplate.new("CV")]
      words = ["tanake", "tekna"]
      
      # Set templates and use multiple times
      analyzer_with_templates = analyzer.with_templates(templates)
      
      analysis1 = analyzer_with_templates.analyze(words)
      analysis2 = analyzer_with_templates.analyze(words, true, 0.3_f32)
      
      # Both should have templates
      analysis1.provided_templates.should_not be_nil
      analysis2.provided_templates.should_not be_nil
      
      analysis1.provided_templates.not_nil!.size.should eq(1)
      analysis2.provided_templates.not_nil!.size.should eq(1)
    end
  end
end