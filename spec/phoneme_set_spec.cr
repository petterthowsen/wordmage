require "./spec_helper"

describe WordMage::PhonemeSet do
  describe "#initialize" do
    it "creates a phoneme set with consonants and vowels" do
      consonants = Set{"p", "t", "k"}
      vowels = Set{"a", "e", "i"}
      phoneme_set = WordMage::PhonemeSet.new(consonants, vowels)
      
      phoneme_set.consonant_symbols.should eq(consonants)
      phoneme_set.vowel_symbols.should eq(vowels)
    end
  end

  describe "#add_phoneme" do
    it "adds a phoneme with positional constraints" do
      phoneme_set = WordMage::PhonemeSet.new(Set(String).new, Set(String).new)
      phoneme_set.add_phoneme("p", :consonant, [:word_initial, :syllable_initial])
      
      phoneme_set.consonant_symbols.should contain("p")
      phoneme_set.get_consonants(:word_initial).should contain("p")
    end
  end

  describe "#add_weight" do
    it "adds weight for a phoneme" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      phoneme_set.add_weight("p", 2.0_f32)
      
      phoneme_set.symbol_weights["p"].should eq(2.0_f32)
    end
  end

  describe "#get_consonants" do
    it "returns all consonants when no position specified" do
      consonants = Set{"p", "t", "k"}
      phoneme_set = WordMage::PhonemeSet.new(consonants, Set(String).new)
      
      phoneme_set.get_consonants.should eq(consonants.to_a)
    end

    it "returns consonants filtered by position" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t", "k"}, Set(String).new)
      phoneme_set.add_phoneme("p", :consonant, [:word_initial])
      phoneme_set.add_phoneme("t", :consonant, [:word_medial])
      
      phoneme_set.get_consonants(:word_initial).should eq(["p"])
    end
  end

  describe "#get_vowels" do
    it "returns all vowels when no position specified" do
      vowels = Set{"a", "e", "i"}
      phoneme_set = WordMage::PhonemeSet.new(Set(String).new, vowels)
      
      phoneme_set.get_vowels.should eq(vowels.to_a)
    end

    it "returns vowels filtered by position" do
      phoneme_set = WordMage::PhonemeSet.new(Set(String).new, Set{"a", "e", "i"})
      phoneme_set.add_phoneme("a", :vowel, [:word_initial])
      phoneme_set.add_phoneme("e", :vowel, [:word_medial])
      
      phoneme_set.get_vowels(:word_initial).should eq(["a"])
    end
  end

  describe "#is_vowel?" do
    it "returns true for vowels" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      phoneme_set.is_vowel?("a").should be_true
    end

    it "returns false for consonants" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      phoneme_set.is_vowel?("p").should be_false
    end

    it "returns false for unknown phonemes" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})
      phoneme_set.is_vowel?("x").should be_false
    end
  end

  describe "#sample_phoneme" do
    it "samples a consonant" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a"})
      consonant = phoneme_set.sample_phoneme(:consonant)
      
      ["p", "t"].should contain(consonant)
    end

    it "samples a vowel" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a", "e"})
      vowel = phoneme_set.sample_phoneme(:vowel)
      
      ["a", "e"].should contain(vowel)
    end

    it "respects positional constraints" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set(String).new)
      phoneme_set.add_phoneme("p", :consonant, [:word_initial])
      
      # Should only return "p" for word_initial position
      10.times do
        consonant = phoneme_set.sample_phoneme(:consonant, :word_initial)
        consonant.should eq("p")
      end
    end

    it "uses weighted sampling when weights are provided" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set(String).new)
      phoneme_set.add_weight("p", 10.0_f32)
      phoneme_set.add_weight("t", 0.1_f32)
      
      # With these weights, "p" should be much more likely
      results = (1..100).map { phoneme_set.sample_phoneme(:consonant) }
      p_count = results.count("p")
      t_count = results.count("t")
      
      # "p" should appear significantly more often than "t"
      p_count.should be > t_count
    end
  end
end