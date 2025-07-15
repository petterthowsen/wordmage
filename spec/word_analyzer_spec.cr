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
      analysis = analyzer.analyze(words, templates)
      
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
      analysis = analyzer.analyze(words, templates)
      
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
      analysis = analyzer.analyze(words, templates)
      
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
      analysis = analyzer.analyze(words, templates)
      
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
      
      analysis = analyzer.analyze([] of String, templates)
      
      analysis.average_syllable_count.should eq(0.0)
      analysis.phoneme_frequencies.should be_empty
      analysis.provided_templates.should_not be_nil
      analysis.provided_templates.not_nil!.size.should eq(2)
    end
  end
end