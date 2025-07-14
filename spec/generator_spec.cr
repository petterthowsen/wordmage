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
  end
end