require "./spec_helper"

describe "IPA Integration with Custom Groups" do
  describe "IPA vowel detection in custom groups" do
    it "detects IPA vowels not in local vowel set as vowel-like" do
      # Create PhonemeSet with limited local vowels
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})  # Only 'a' and 'e' as local vowels
      
      # Add custom group with IPA vowels not in local set
      phoneme_set.add_custom_group('I', ["ɪ", "ʊ", "ə"])  # IPA vowels not in local set
      
      # Should be detected as vowel-like due to IPA classification
      phoneme_set.is_vowel_like_group?('I').should be_true
    end

    it "detects mixed groups correctly" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      
      # Mixed group with IPA vowels and consonants
      phoneme_set.add_custom_group('M', ["ɪ", "p", "ə"])  # IPA vowels + consonant
      
      # Should NOT be vowel-like due to consonant presence
      phoneme_set.is_vowel_like_group?('M').should be_false
    end

    it "works with pure IPA consonant groups" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      
      # IPA consonants not in local consonant set
      phoneme_set.add_custom_group('F', ["ʃ", "ʒ", "θ"])  # IPA fricatives
      
      # Should NOT be vowel-like
      phoneme_set.is_vowel_like_group?('F').should be_false
    end

    it "PhonemeSet.is_vowel? uses IPA fallback" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})  # Only 'a' as local vowel
      
      # Local vowel should return true
      phoneme_set.is_vowel?("a").should be_true
      
      # IPA vowels not in local set should also return true
      phoneme_set.is_vowel?("ɪ").should be_true
      phoneme_set.is_vowel?("ʊ").should be_true
      phoneme_set.is_vowel?("ə").should be_true
      
      # Consonants should return false
      phoneme_set.is_vowel?("p").should be_false
      phoneme_set.is_vowel?("ʃ").should be_false
    end
  end

  describe "Custom groups with IPA phonemes" do
    it "can create custom groups with IPA phonemes" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      
      # Create groups with IPA phonemes
      phoneme_set.add_custom_group('X', ["ɪ", "ʊ", "ə", "ɔ"])  # IPA vowels
      phoneme_set.add_custom_group('F', ["ʃ", "ʒ", "θ", "ð"])  # IPA fricatives
      
      # Should successfully sample from these groups
      5.times do
        vowel_phoneme = phoneme_set.sample_phoneme('X')
        ["ɪ", "ʊ", "ə", "ɔ"].should contain(vowel_phoneme)
        
        fricative_phoneme = phoneme_set.sample_phoneme('F')
        ["ʃ", "ʒ", "θ", "ð"].should contain(fricative_phoneme)
      end
    end

    it "generates syllables with IPA phonemes in custom patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      phoneme_set.add_custom_group('F', ["ʃ", "ʒ"])  # IPA fricatives
      phoneme_set.add_custom_group('X', ["ɪ", "ʊ"])  # IPA vowels
      
      # Should generate FXF pattern (fricative-vowel-fricative)
      template = WordMage::SyllableTemplate.new("FXF")
      syllable = template.generate(phoneme_set, :initial)
      
      syllable.size.should eq(3)
      ["ʃ", "ʒ"].should contain(syllable[0])    # F
      ["ɪ", "ʊ"].should contain(syllable[1])    # X (IPA vowel, should work)
      ["ʃ", "ʒ"].should contain(syllable[2])    # F
    end

    it "applies hiatus to IPA vowel-like custom groups" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      phoneme_set.add_custom_group('I', ["ɪ", "ʊ", "ə"])  # IPA vowels
      
      # Should generate hiatus for IPA vowel group
      template = WordMage::SyllableTemplate.new("I", hiatus_probability: 1.0_f32)
      syllable = template.generate(phoneme_set, :initial)
      
      syllable.size.should eq(2)  # Should generate hiatus II
      ["ɪ", "ʊ", "ə"].should contain(syllable[0])
      ["ɪ", "ʊ", "ə"].should contain(syllable[1])
      syllable[0].should_not eq(syllable[1])  # Should be different
    end
  end

  describe "Generator integration with IPA" do
    it "builds generator with IPA phonemes in custom groups" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a", "e"])
        .with_custom_group('I', ["ɪ", "ʊ", "ə"])    # IPA vowels
        .with_custom_group('F', ["ʃ", "ʒ", "θ"])    # IPA fricatives
        .with_syllable_patterns(["IF", "FI"])       # Use IPA vowel groups
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build

      # Should generate words using IPA phonemes
      words = generator.generate_batch(5)
      words.each do |word|
        word.should_not be_empty
        # Hard to test exact content but shouldn't crash
      end
    end
  end
end