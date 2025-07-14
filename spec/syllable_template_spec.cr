require "./spec_helper"

describe WordMage::SyllableTemplate do
  describe "#initialize" do
    it "creates a syllable template with pattern" do
      template = WordMage::SyllableTemplate.new("CV")
      template.pattern.should eq("CV")
    end

    it "creates a syllable template with constraints" do
      constraints = ["rr", "ss"]
      template = WordMage::SyllableTemplate.new("CVC", constraints)
      template.constraints.should eq(constraints)
    end

    it "creates a syllable template with hiatus probability" do
      template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.5_f32)
      template.hiatus_probability.should eq(0.5_f32)
    end
  end

  describe "#generate" do
    it "generates a CV syllable" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CV")
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(2)
      
      # First should be consonant, second should be vowel
      phoneme_set.is_vowel?(syllable[0]).should be_false
      phoneme_set.is_vowel?(syllable[1]).should be_true
    end

    it "generates a CVC syllable" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t", "k"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CVC")
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(3)
      
      # Should be consonant-vowel-consonant
      phoneme_set.is_vowel?(syllable[0]).should be_false
      phoneme_set.is_vowel?(syllable[1]).should be_true
      phoneme_set.is_vowel?(syllable[2]).should be_false
    end

    it "generates a V syllable (vowel-initial)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("V")
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(1)
      phoneme_set.is_vowel?(syllable[0]).should be_true
    end

    it "generates consonant clusters (CCV)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CCV")
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(3)
      
      # Should be consonant-consonant-vowel
      phoneme_set.is_vowel?(syllable[0]).should be_false
      phoneme_set.is_vowel?(syllable[1]).should be_false
      phoneme_set.is_vowel?(syllable[2]).should be_true
    end

    it "respects constraints" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r"}, Set{"a"})
      # Constraint that prevents "rr" sequences
      template = WordMage::SyllableTemplate.new("CC", ["rr"])
      
      # This should retry until it finds a valid combination
      # Since we only have "r" consonants, it should keep retrying
      # We'll test this differently - with multiple consonants where constraint can be avoided
      phoneme_set2 = WordMage::PhonemeSet.new(Set{"p", "r"}, Set{"a"})
      template2 = WordMage::SyllableTemplate.new("CC", ["rr"])
      
      syllable = template2.generate(phoneme_set2, :initial)
      sequence = syllable.join
      sequence.should_not match(/rr/)
    end
  end

  describe "#allows_hiatus?" do
    it "returns true when hiatus probability is greater than 0" do
      template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.5_f32)
      template.allows_hiatus?.should be_true
    end

    it "returns false when hiatus probability is 0" do
      template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.0_f32)
      template.allows_hiatus?.should be_false
    end
  end

  describe "#validate" do
    it "validates syllable against constraints" do
      constraints = ["rr", "ss"]
      template = WordMage::SyllableTemplate.new("CVC", constraints)
      
      # Valid syllable
      template.validate(["p", "a", "t"]).should be_true
      
      # Invalid syllable (contains "rr")
      template.validate(["r", "r"]).should be_false
    end

    it "returns true when no constraints" do
      template = WordMage::SyllableTemplate.new("CV")
      template.validate(["r", "r"]).should be_true
    end
  end

  describe "hiatus generation" do
    it "can generate vowel-vowel sequences (hiatus)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a", "e", "i", "o"})
      template = WordMage::SyllableTemplate.new("V", hiatus_probability: 1.0_f32)
      
      # With 100% hiatus probability, should always generate VV
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(2)
      phoneme_set.is_vowel?(syllable[0]).should be_true
      phoneme_set.is_vowel?(syllable[1]).should be_true
    end

    it "generates normal vowels with 0% hiatus probability" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("V", hiatus_probability: 0.0_f32)
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(1)
      phoneme_set.is_vowel?(syllable[0]).should be_true
    end

    it "can generate complex patterns with hiatus (CVV)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"t"}, Set{"a", "e", "i"})
      template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 1.0_f32)
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(3) # C + V + V (hiatus)
      phoneme_set.is_vowel?(syllable[0]).should be_false
      phoneme_set.is_vowel?(syllable[1]).should be_true
      phoneme_set.is_vowel?(syllable[2]).should be_true
    end
  end
end