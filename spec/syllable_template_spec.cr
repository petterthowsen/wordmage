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

    it "creates a syllable template with custom probability" do
      template = WordMage::SyllableTemplate.new("CV", probability: 2.5_f32)
      template.probability.should eq(2.5_f32)
    end

    it "defaults probability to 1.0 when not specified" do
      template = WordMage::SyllableTemplate.new("CV")
      template.probability.should eq(1.0_f32)
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

    it "generates consonant clusters (CCV) with explicit clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: ["pr", "tr"])
      
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(3)
      
      # Should be consonant-consonant-vowel
      phoneme_set.is_vowel?(syllable[0]).should be_false
      phoneme_set.is_vowel?(syllable[1]).should be_false
      phoneme_set.is_vowel?(syllable[2]).should be_true
      
      # Should only be allowed clusters
      cluster = syllable[0] + syllable[1]
      ["pr", "tr"].should contain(cluster)
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

  describe "cluster-only consonant adjacency" do
    it "prevents illegal consonant sequences in CVC patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"f", "v", "z", "p", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CVC")
      
      # Generate many syllables and ensure no illegal consonant sequences
      100.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(3)
        
        # Should never have consonants adjacent in CVC (only separated by vowel)
        phoneme_set.is_vowel?(syllable[0]).should be_false  # C
        phoneme_set.is_vowel?(syllable[1]).should be_true   # V
        phoneme_set.is_vowel?(syllable[2]).should be_false  # C
        
        # No illegal combinations like "fv", "zp", etc.
        sequence = syllable.join
        sequence.should_not match(/[fvz][fvz]/)  # No fricative clusters
        sequence.should_not match(/[ptk][ptk]/)  # No plosive clusters
      end
    end

    it "only allows defined onset clusters in CCV patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t", "f", "l"}, Set{"a", "e"})
      allowed_clusters = ["pr", "tr"]
      template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: allowed_clusters)
      
      # Generate many syllables and ensure only allowed clusters appear
      50.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(3)
        
        # First two should be consonants forming allowed cluster
        phoneme_set.is_vowel?(syllable[0]).should be_false
        phoneme_set.is_vowel?(syllable[1]).should be_false
        phoneme_set.is_vowel?(syllable[2]).should be_true
        
        # Should only be allowed clusters
        cluster = syllable[0] + syllable[1]
        allowed_clusters.should contain(cluster)
      end
    end

    it "only allows defined coda clusters in CVCC patterns" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"n", "d", "t", "s", "p"}, Set{"a", "e"})
      allowed_coda_clusters = ["nd", "st"]
      template = WordMage::SyllableTemplate.new("CVCC", allowed_coda_clusters: allowed_coda_clusters)
      
      # Generate many syllables and ensure only allowed coda clusters appear
      50.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(4)
        
        # Should be C-V-CC pattern
        phoneme_set.is_vowel?(syllable[0]).should be_false  # C
        phoneme_set.is_vowel?(syllable[1]).should be_true   # V
        phoneme_set.is_vowel?(syllable[2]).should be_false  # C
        phoneme_set.is_vowel?(syllable[3]).should be_false  # C
        
        # Last two consonants should form allowed coda cluster
        coda_cluster = syllable[2] + syllable[3]
        allowed_coda_clusters.should contain(coda_cluster)
      end
    end

    it "rejects CCV patterns without allowed clusters defined" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CCV") # No allowed_clusters defined
      
      # Should fallback to simpler pattern or use individual consonants
      syllable = template.generate(phoneme_set, :initial)
      
      # Should either fallback to CV or use fallback mechanism
      (syllable.size == 2 || syllable.size == 3).should be_true
    end

    it "prevents gemination within syllables" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"r", "s", "t"}, Set{"a", "e"})
      template = WordMage::SyllableTemplate.new("CVC")
      
      # Generate many syllables and ensure no gemination
      100.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(3)
        
        # No identical adjacent phonemes
        syllable[0].should_not eq(syllable[1])
        syllable[1].should_not eq(syllable[2])
      end
    end

    it "allows complex multi-consonant patterns only with explicit clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"s", "p", "r", "t"}, Set{"a", "e"})
      allowed_onset_clusters = ["sp", "pr"]
      allowed_coda_clusters = ["st"]
      
      template = WordMage::SyllableTemplate.new("CCVCC", 
        allowed_clusters: allowed_onset_clusters,
        allowed_coda_clusters: allowed_coda_clusters)
      
      10.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(5)
        
        # Onset cluster should be allowed
        onset_cluster = syllable[0] + syllable[1]
        allowed_onset_clusters.should contain(onset_cluster)
        
        # Middle should be vowel
        phoneme_set.is_vowel?(syllable[2]).should be_true
        
        # Coda cluster should be allowed
        coda_cluster = syllable[3] + syllable[4]
        allowed_coda_clusters.should contain(coda_cluster)
      end
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

    it "generates different vowels for hiatus (no gemination)" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a", "e", "i", "o"})
      template = WordMage::SyllableTemplate.new("V", hiatus_probability: 1.0_f32)
      
      # Generate many hiatus sequences and verify no gemination
      50.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(2)
        # First and second vowel should be different
        syllable[0].should_not eq(syllable[1])
      end
    end

    it "falls back to same vowel only when no alternatives exist" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p"}, Set{"a"})  # Only one vowel
      template = WordMage::SyllableTemplate.new("V", hiatus_probability: 1.0_f32)
      
      # With only one vowel available, should still generate hiatus but same vowel
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should eq(2)
      syllable[0].should eq("a")
      syllable[1].should eq("a")  # Forced repetition when no alternatives
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