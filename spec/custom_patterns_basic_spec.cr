require "./spec_helper"

describe "Custom Pattern Elements - Basic" do
  describe "PhonemeSet custom groups" do
    it "adds and retrieves custom groups" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t", "k", "f", "s"}, Set{"a", "e", "i"})
      
      phoneme_set.add_custom_group('F', ["f", "s"])
      phoneme_set.has_custom_group?('F').should be_true
      phoneme_set.get_custom_group('F').should contain("f")
      phoneme_set.get_custom_group('F').should contain("s")
    end

    it "prevents reserved symbols C and V" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      
      expect_raises(Exception, "Symbol 'C' is reserved") do
        phoneme_set.add_custom_group('C', ["p"])
      end
      
      expect_raises(Exception, "Symbol 'V' is reserved") do
        phoneme_set.add_custom_group('V', ["a"])
      end
    end

    it "detects vowel-like groups automatically" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e", "i", "o"})
      
      # Vowel-only group should be vowel-like
      phoneme_set.add_custom_group('H', ["a", "e"])  # High vowels
      phoneme_set.is_vowel_like_group?('H').should be_true
      
      # Consonant-only group should not be vowel-like
      phoneme_set.add_custom_group('F', ["p", "t"])  # Fricatives  
      phoneme_set.is_vowel_like_group?('F').should be_false
    end

    it "samples from custom groups" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t", "k"}, Set{"a", "e"})
      phoneme_set.add_custom_group('F', ["f", "s", "z"])
      
      # Sample should return one of the phonemes from the group
      5.times do
        phoneme = phoneme_set.sample_phoneme('F')
        ["f", "s", "z"].should contain(phoneme)
      end
    end
  end

  describe "SyllableTemplate with custom patterns" do
    it "generates syllables using custom patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t", "k"}, Set{"a", "e", "i"})
      phoneme_set.add_custom_group('F', ["f", "s"])
      
      template = WordMage::SyllableTemplate.new("FVC")
      syllable = template.generate(phoneme_set, :initial)
      
      syllable.size.should eq(3)
      ["f", "s"].should contain(syllable[0])    # F
      ["a", "e", "i"].should contain(syllable[1])  # V  
      ["p", "t", "k"].should contain(syllable[2])  # C
    end

    it "raises error for undefined symbols in patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      template = WordMage::SyllableTemplate.new("XVC")
      
      expect_raises(Exception, "Unknown pattern symbol 'X'") do
        template.generate(phoneme_set, :initial)
      end
    end
  end

  describe "GeneratorBuilder with custom groups" do
    it "builds generator with custom groups" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t", "k", "f", "s"], ["a", "e", "i"])
        .with_custom_group('F', ["f", "s"])
        .with_syllable_patterns(["FVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build

      word = generator.generate
      word.should_not be_empty
      word.size.should be > 0
    end

    it "validates pattern symbols during build" do
      expect_raises(Exception, "Pattern symbol 'X' is not defined") do
        WordMage::GeneratorBuilder.create
          .with_phonemes(["p"], ["a"])
          .with_syllable_patterns(["XVC"])  # Undefined symbol X
          .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
          .build
      end
    end
  end
end