require "./spec_helper"

describe WordMage::GenerationMode do
  it "defines Random mode" do
    WordMage::GenerationMode::Random.should be_a(WordMage::GenerationMode)
  end

  it "defines Sequential mode" do
    WordMage::GenerationMode::Sequential.should be_a(WordMage::GenerationMode)
  end

  it "defines WeightedRandom mode" do
    WordMage::GenerationMode::WeightedRandom.should be_a(WordMage::GenerationMode)
  end
end

describe WordMage::Generator do
  describe "#initialize" do
    it "creates a generator with all components" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      generator.phoneme_set.should eq(phoneme_set)
      generator.word_spec.should eq(word_spec)
      generator.romanizer.should eq(romanizer)
      generator.mode.should eq(WordMage::GenerationMode::Random)
    end
  end

  describe "#generate" do
    it "generates a word in random mode" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      word = generator.generate
      word.should be_a(String)
      word.size.should be > 0
    end

    it "generates words starting with vowels when specified" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("V"), WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        starting_type: :vowel
      )
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words to verify they all start with vowels
      10.times do
        word = generator.generate
        first_char = word[0].to_s
        phoneme_set.is_vowel?(first_char).should be_true
      end
    end

    it "generates words starting with consonants when specified" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        starting_type: :consonant
      )
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words to verify they all start with consonants
      10.times do
        word = generator.generate
        first_char = word[0].to_s
        phoneme_set.is_vowel?(first_char).should be_false
      end
    end

    it "generates words of exactly 3 syllables" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(3)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      word = generator.generate
      # Each CV syllable = 2 characters, 3 syllables = 6 characters
      word.size.should eq(6)
    end

    it "generates words between 2 and 4 syllables" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.range(2, 4)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify syllable count range
      10.times do
        word = generator.generate
        # Each CV syllable = 2 characters
        syllable_count = word.size / 2
        syllable_count.should be >= 2
        syllable_count.should be <= 4
      end
    end

    it "generates words with vowel-vowel sequences (hiatus)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "r"}, Set{"a", "e", "o"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      # Template with guaranteed hiatus
      templates = [WordMage::SyllableTemplate.new("CV", hiatus_probability: 1.0_f32)]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      word = generator.generate
      # Should contain vowel sequences like "taeros" or "tionor"
      # With 100% hiatus, each syllable becomes CVV instead of CV
      # 2 syllables * 3 chars each = 6 chars
      word.size.should eq(6)
      
      # Verify it contains adjacent vowels
      has_vowel_sequence = false
      (0...word.size-1).each do |i|
        char1 = word[i].to_s
        char2 = word[i+1].to_s
        if phoneme_set.is_vowel?(char1) && phoneme_set.is_vowel?(char2)
          has_vowel_sequence = true
          break
        end
      end
      has_vowel_sequence.should be_true
    end

    it "generates words using consonant clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t", "s"}, Set{"a", "e", "o"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      # CCV pattern creates consonant clusters
      templates = [WordMage::SyllableTemplate.new("CCV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      word = generator.generate
      # Each CCV syllable = 3 characters, 2 syllables = 6 characters
      word.size.should eq(6)
      
      # Verify it contains consonant clusters (CC patterns)
      has_consonant_cluster = false
      (0...word.size-1).each do |i|
        char1 = word[i].to_s
        char2 = word[i+1].to_s
        if !phoneme_set.is_vowel?(char1) && !phoneme_set.is_vowel?(char2)
          has_consonant_cluster = true
          break
        end
      end
      has_consonant_cluster.should be_true
    end

    it "respects weighted sampling" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      # Weight "p" much higher than "t"
      phoneme_set.add_weight("p", 10.0_f32)
      phoneme_set.add_weight("t", 0.1_f32)
      
      syllable_count = WordMage::SyllableCountSpec.exact(1)
      templates = [WordMage::SyllableTemplate.new("C")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::WeightedRandom
      )
      
      # Generate many words and verify "p" appears much more often than "t"
      results = (1..100).map { generator.generate }
      p_count = results.count("p")
      t_count = results.count("t")
      
      # "p" should appear significantly more often than "t"
      p_count.should be > t_count
    end
  end

  describe "sequential generation" do
    it "generates words sequentially" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Sequential,
        max_words: 8
      )
      
      words = [] of String
      while word = generator.next_sequential
        words << word
      end
      
      # Should generate all combinations: ra, re, ta, te
      expected = ["ra", "re", "ta", "te"]
      expected.each do |expected_word|
        words.should contain(expected_word)
      end
    end

    it "respects max_words limit" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Sequential,
        max_words: 2
      )
      
      words = [] of String
      while word = generator.next_sequential
        words << word
      end
      
      words.size.should eq(2)
    end

    it "can be reset" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r"}, Set{"a"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Sequential,
        max_words: 2
      )
      
      # Generate first word
      first_word = generator.next_sequential
      first_word.should eq("ra")
      
      # Reset and generate again
      generator.reset_sequential
      reset_word = generator.next_sequential
      reset_word.should eq("ra")
    end
  end

  describe "#generate_batch" do
    it "generates multiple words" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      words = generator.generate_batch(5)
      words.size.should eq(5)
      words.each do |word|
        word.should be_a(String)
        word.size.should be > 0
      end
    end
  end

  describe "flexible generation methods" do
    it "generates words with specific syllable count" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.range(1, 3)  # Default range
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate 5-syllable word (overriding default range)
      word = generator.generate(5)
      word.size.should eq(10)  # 5 syllables * 2 chars each (CV)
    end

    it "generates words with syllable count range" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)  # Default
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate words with 2-4 syllables (overriding default)
      10.times do
        word = generator.generate(2, 4)
        syllables = word.size / 2
        syllables.should be >= 2
        syllables.should be <= 4
      end
    end

    it "generates words with specific starting type" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV"), WordMage::SyllableTemplate.new("V")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate vowel-initial words
      10.times do
        word = generator.generate(:vowel)
        first_char = word[0].to_s
        phoneme_set.is_vowel?(first_char).should be_true
      end
      
      # Generate consonant-initial words
      10.times do
        word = generator.generate(:consonant)
        first_char = word[0].to_s
        phoneme_set.is_vowel?(first_char).should be_false
      end
    end

    it "generates words with both syllable count and starting type" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(1)  # Default
      templates = [WordMage::SyllableTemplate.new("CV"), WordMage::SyllableTemplate.new("V")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate 3-syllable vowel-initial words
      10.times do
        word = generator.generate(3, :vowel)
        word.size.should be >= 3  # At least 3 syllables (could be V + CV + CV = 4 chars)
        first_char = word[0].to_s
        phoneme_set.is_vowel?(first_char).should be_true
      end
    end
  end

  describe "complex constraint validation" do
    it "respects word-level constraints" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r", "p"}, Set{"a"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      # Prevent "rr" sequences at word level
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        word_constraints: ["rr"]
      )
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify none contain "rr"
      10.times do
        word = generator.generate
        word.should_not match(/rr/)
      end
    end

    it "prevents gemination across syllable boundaries automatically" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify no gemination across syllable boundaries
      50.times do
        word = generator.generate
        # Should not have double vowels or consonants across syllable boundaries
        word.should_not match(/aa|ee|pp|tt/)
      end
    end

    it "prevents excessive vowel sequences across syllable boundaries" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e", "i", "o", "u"})
      syllable_count = WordMage::SyllableCountSpec.exact(3)
      # Use templates that can create hiatus and vowel-initial syllables
      hiatus_template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.5_f32)
      vowel_template = WordMage::SyllableTemplate.new("V")
      templates = [hiatus_template, vowel_template]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      romanizer = WordMage::RomanizationMap.new
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify no 3+ consecutive vowels
      50.times do
        word = generator.generate
        # Should not have 3+ consecutive vowels like "aei", "uao", "iou", etc.
        word.should_not match(/[aeiou]{3,}/)
      end
    end
  end

  describe "thematic vowel constraints" do
    it "enforces thematic vowel constraint with exact syllable count" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "n", "k", "r", "s"}, Set{"a", "e", "i", "o"})
      syllable_count = WordMage::SyllableCountSpec.exact(3)
      templates = [WordMage::SyllableTemplate.new("CV"), WordMage::SyllableTemplate.new("CVC")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        thematic_vowel: "a"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s", "a" => "a", "e" => "e", "i" => "i", "o" => "o"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify they all end with 'a'
      10.times do
        word = generator.generate
        word.should be_a(String)
        word.size.should be > 0
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(3)
        
        # Check that last vowel is 'a'
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("a")
      end
    end

    it "enforces thematic vowel constraint with syllable range" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "n", "k"}, Set{"a", "e", "i"})
      syllable_count = WordMage::SyllableCountSpec.range(2, 4)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        thematic_vowel: "e"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e", "i" => "i"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify syllable counts and thematic vowel
      15.times do
        word = generator.generate
        
        # Use word analyzer to verify syllable count is in range
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 4
        
        # Check that last vowel is 'e'
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("e")
      end
    end

    it "enforces thematic vowel with different syllable patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "r", "s", "l"}, Set{"a", "o", "u"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        thematic_vowel: "o"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "r" => "r", "s" => "s", "l" => "l", "a" => "a", "o" => "o", "u" => "u"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate words with different patterns and verify thematic vowel
      20.times do
        word = generator.generate
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(2)
        
        # Check that last vowel is 'o'
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("o")
      end
    end

    it "works with hiatus and maintains thematic vowel" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "k", "n"}, Set{"a", "e", "i"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      # Template with hiatus to create vowel sequences
      templates = [WordMage::SyllableTemplate.new("CV", hiatus_probability: 1.0_f32)]
      word_spec = WordMage::WordSpec.new(
        syllable_count: WordMage::SyllableCountSpec.exact(4),
        syllable_templates: templates,
        thematic_vowel: "i"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "k" => "k", "n" => "n", "a" => "a", "e" => "e", "i" => "i"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate words with hiatus and verify thematic vowel still applies
      10.times do
        word = generator.generate
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(7)
        
        # Should have vowel sequences due to hiatus
        has_vowel_sequence = false
        (0...word.size-1).each do |i|
          char1 = word[i].to_s
          char2 = word[i+1].to_s
          if phoneme_set.is_vowel?(char1) && phoneme_set.is_vowel?(char2)
            has_vowel_sequence = true
            break
          end
        end
        has_vowel_sequence.should be_true
        
        # Check that last vowel is still 'i' despite hiatus
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("i")
      end
    end

    it "works with consonant clusters and maintains thematic vowel" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"s", "t", "r", "p"}, Set{"a", "e"})
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      # CCV creates consonant clusters
      templates = [WordMage::SyllableTemplate.new("CCV"), WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        thematic_vowel: "a"
      )
      romanizer = WordMage::RomanizationMap.new({"s" => "s", "t" => "t", "r" => "r", "p" => "p", "a" => "a", "e" => "e"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate words with clusters and verify thematic vowel
      15.times do
        word = generator.generate
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(2)
        
        # Check that last vowel is 'a'
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("a")
      end
    end

    it "validates thematic vowel is in phoneme set" do
      # This should raise an error because "i" is not in the vowel set
      expect_raises(ArgumentError, "Thematic vowel 'i' is not in the vowel set") do
        WordMage::GeneratorBuilder.create
          .with_phonemes(["t", "n"], ["a", "e"])
          .with_syllable_patterns(["CV"])
          .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
          .with_thematic_vowel("i")
          .build
      end
    end
  end

  describe "sequence constraints" do
    it "enforces starting_with_sequence constraint" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "h", "r", "a", "n", "s", "k"], ["a", "e", "i", "o"])
        .with_syllable_patterns(["CV", "CVC", "CCV"])
        .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
        .starting_with_sequence("thr")
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "a" => "a", "n" => "n", "s" => "s", "k" => "k", "e" => "e", "i" => "i", "o" => "o"})
      
      # Generate multiple words and verify they all start with "thr"
      15.times do
        word = generator.generate
        word.should start_with("thr")
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
# puts "DEBUG: Word '#{word}' has #{analysis.syllable_count} syllables (expected 2-4)"
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 4
      end
    end

    it "enforces ending_with_sequence constraint" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "h", "r", "a", "n", "s", "k"}, Set{"a", "e", "i", "o"})
      syllable_count = WordMage::SyllableCountSpec.range(2, 3)
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        ends_with: "ath"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "a" => "a", "n" => "n", "s" => "s", "k" => "k", "e" => "e", "i" => "i", "o" => "o"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify they all end with "ath"
      15.times do
        word = generator.generate
        word.should end_with("ath")
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 3
      end
    end

    it "combines starting and ending sequence constraints" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "h", "r", "a", "n", "s", "k", "e", "l"}, Set{"a", "e", "i", "o"})
      syllable_count = WordMage::SyllableCountSpec.range(3, 4)
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC"),
        WordMage::SyllableTemplate.new("CCV")
      ]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        starts_with: "thr",
        ends_with: "ath"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "a" => "a", "n" => "n", "s" => "s", "k" => "k", "e" => "e", "i" => "i", "o" => "o", "l" => "l"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify both constraints
      10.times do
        word = generator.generate
        word.should start_with("thr")
        word.should end_with("ath")
        
        # Use word analyzer to verify syllable count  
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should be >= 3
        analysis.syllable_count.should be <= 4
      end
    end

    it "combines sequence constraints with thematic vowel" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t", "h", "r", "a", "n", "s", "k", "e"}, Set{"a", "e", "i", "o"})
      syllable_count = WordMage::SyllableCountSpec.exact(3)
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        starts_with: "th",
        thematic_vowel: "a"
      )
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "a" => "a", "n" => "n", "s" => "s", "k" => "k", "e" => "e", "i" => "i", "o" => "o"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate multiple words and verify all constraints
      10.times do
        word = generator.generate
        word.should start_with("th")
        
        # Check that last vowel is 'a' (thematic vowel)
        last_vowel = nil
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("a")
        
        # Use word analyzer to verify syllable count
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(3)
      end
    end

    it "validates sequence constraints with diverse syllable patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"s", "p", "r", "t", "k", "n"}, Set{"a", "e", "o"})
      syllable_count = WordMage::SyllableCountSpec.range(2, 3)
      templates = [
        WordMage::SyllableTemplate.new("V"),
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC"),
        WordMage::SyllableTemplate.new("CCV"),
        WordMage::SyllableTemplate.new("CCVC")
      ]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        starts_with: "spr"
      )
      romanizer = WordMage::RomanizationMap.new({"s" => "s", "p" => "p", "r" => "r", "t" => "t", "k" => "k", "n" => "n", "a" => "a", "e" => "e", "o" => "o"})
      
      generator = WordMage::Generator.new(
        phoneme_set: phoneme_set,
        word_spec: word_spec,
        romanizer: romanizer,
        mode: WordMage::GenerationMode::Random
      )
      
      # Generate words with complex patterns and verify constraints
      10.times do
        word = generator.generate
        word.should start_with("spr")
        
        # Use word analyzer to verify proper syllable structure
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 3
        
        # Should contain consonant clusters due to CCV/CCVC patterns
        analysis.cluster_count.should be >= 1
      end
    end
  end

  describe "phonological features" do
    it "generates words with gemination (consonant doubling)" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "n", "k", "r", "s"], ["a", "e", "i", "o"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
        .with_gemination_probability(1.0)  # 100% gemination
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s", "a" => "a", "e" => "e", "i" => "i", "o" => "o"})
      
      # Generate multiple words and verify gemination occurs
      found_gemination = false
      20.times do
        word = generator.generate
        
        # Use word analyzer to detect gemination
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        
        if analysis.gemination_sequences.size > 0
          found_gemination = true
          analysis.gemination_sequences.each do |gemination|
            gemination.size.should eq(2)  # Double consonants
          end
        end
        
        # Verify syllable count
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 4
      end
      
      found_gemination.should be_true
    end

    it "generates words with vowel lengthening (vowel doubling)" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "n", "k"], ["a", "e", "i", "o"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
        .with_vowel_lengthening_probability(1.0)  # 100% vowel lengthening
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e", "i" => "i", "o" => "o"})
      
      # Generate multiple words and verify vowel lengthening occurs
      found_lengthening = false
      20.times do
        word = generator.generate
        
        # Use word analyzer to detect vowel lengthening
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        
        if analysis.vowel_lengthening_sequences.size > 0
          found_lengthening = true
          analysis.vowel_lengthening_sequences.each do |lengthening|
            lengthening.size.should eq(2)  # Double vowels
          end
        end
        
        # Verify syllable count (allow +1 for vowel lengthening effects)
        analysis.syllable_count.should be >= 2
        analysis.syllable_count.should be <= 4
      end
      
      found_lengthening.should be_true
    end

    it "combines gemination and vowel lengthening features" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "n", "r", "s"], ["a", "e", "i"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(3))
        .with_gemination_probability(0.7)      # 70% gemination
        .with_vowel_lengthening_probability(0.5)  # 50% vowel lengthening
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "r" => "r", "s" => "s", "a" => "a", "e" => "e", "i" => "i"})
      
      # Generate multiple words and check for both features
      found_both = false
      30.times do
        word = generator.generate
        
        # Use word analyzer to detect both features
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        
        has_gemination = analysis.gemination_sequences.size > 0
        has_lengthening = analysis.vowel_lengthening_sequences.size > 0
        
        if has_gemination && has_lengthening
          found_both = true
          break
        end
        
        # Verify syllable count
        analysis.syllable_count.should eq(3)
      end
      
      # With 70% and 50% probabilities over 30 attempts, we should find both
      # This is probabilistic but very likely to succeed
      found_both.should be_true
    end

    it "respects gemination probability settings" do
      # Test with 0% gemination - should never occur
      generator_no_gem = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "n", "k"], ["a", "e"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(3))
        .with_gemination_probability(0.0)  # 0% gemination
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"})
      
      # Generate words and verify no gemination
      10.times do
        word = generator_no_gem.generate
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.gemination_sequences.size.should eq(0)
      end
    end

    it "uses convenience methods for enabling/disabling features" do
      # Test enable_gemination convenience method
      generator_enabled = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "n", "s"], ["a", "e"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
        .enable_gemination  # Should set 100% probability
        .disable_vowel_lengthening  # Should set 0% probability
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "s" => "s", "a" => "a", "e" => "e"})
      
      # Should find gemination but no vowel lengthening
      found_gemination = false
      found_lengthening = false
      
      15.times do
        word = generator_enabled.generate
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        
        if analysis.gemination_sequences.size > 0
          found_gemination = true
        end
        if analysis.vowel_lengthening_sequences.size > 0
          found_lengthening = true
        end
      end
      
      found_gemination.should be_true
      found_lengthening.should be_false
    end

    it "integrates phonological features with other constraints" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["t", "h", "r", "n", "s"], ["a", "e", "o"])
        .with_syllable_patterns(["CV", "CVC", "CCV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(3))
        .with_thematic_vowel("a")
        .with_gemination_probability(0.8)
        .build
      
      romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "n" => "n", "s" => "s", "a" => "a", "e" => "e", "o" => "o"})
      
      # Generate words and verify all constraints work together
      10.times do
        word = generator.generate
        
        # Check thematic vowel constraint
        last_vowel = nil
        romanizer = WordMage::RomanizationMap.new({"t" => "t", "h" => "h", "r" => "r", "n" => "n", "s" => "s", "a" => "a", "e" => "e", "o" => "o"})
        phoneme_set = WordMage::PhonemeSet.new(Set{"t", "h", "r", "n", "s"}, Set{"a", "e", "o"})
        word.chars.reverse.each do |char|
          if phoneme_set.is_vowel?(char.to_s)
            last_vowel = char.to_s
            break
          end
        end
        last_vowel.should eq("a")
        
        # Use word analyzer to verify syllable count and detect features
        analyzer = WordMage::WordAnalyzer.new(romanizer)
        analysis = analyzer.analyze(word)
        analysis.syllable_count.should eq(3)
      end
    end
  end
end