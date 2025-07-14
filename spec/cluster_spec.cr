require "./spec_helper"

describe "Cluster Support" do
  describe "SyllableTemplate with allowed clusters" do
    it "generates only allowed clusters when specified" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t", "k", "d", "s"}, Set{"a", "e", "i"})
      allowed_clusters = ["pr", "tr", "kr", "dr"]
      
      template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: allowed_clusters)
      
      # Generate multiple syllables and verify they all use allowed clusters
      100.times do
        syllable = template.generate(phoneme_set, :initial)
        cluster = syllable[0..1].join
        allowed_clusters.should contain(cluster)
      end
    end

    it "rejects syllables with disallowed clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t", "k"}, Set{"a", "e"})
      allowed_clusters = ["pr", "tr"]  # Only these two allowed
      
      template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: allowed_clusters)
      
      # Should never generate "pk", "pt", "rp", "rt", "tk", "tp", etc.
      50.times do
        syllable = template.generate(phoneme_set, :initial)
        cluster = syllable[0..1].join
        ["pk", "pt", "rp", "rt", "tk", "tp", "kr", "kt", "kp"].should_not contain(cluster)
      end
    end

    it "works with three-consonant clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"s", "p", "r", "t"}, Set{"a", "e"})
      allowed_clusters = ["spr", "str"]
      
      template = WordMage::SyllableTemplate.new("CCCV", allowed_clusters: allowed_clusters)
      
      10.times do
        syllable = template.generate(phoneme_set, :initial)
        syllable.size.should eq(4)  # CCC + V
        cluster = syllable[0..2].join
        allowed_clusters.should contain(cluster)
      end
    end

    it "falls back to single consonants when no clusters match" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "t"}, Set{"a"})
      allowed_clusters = ["kr"]  # Impossible with available phonemes
      
      template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: allowed_clusters)
      
      # Should generate CV instead of CCV when cluster impossible
      syllable = template.generate(phoneme_set, :initial)
      syllable.size.should be <= 2  # Should fall back to CV
    end
  end

  describe "Generator with cluster constraints" do
    it "generates words using only specified clusters" do
      phoneme_set = WordMage::PhonemeSet.new(Set{"p", "r", "t", "k", "d"}, Set{"a", "e", "o"})
      allowed_clusters = ["pr", "tr", "dr"]
      
      cluster_template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: allowed_clusters)
      regular_template = WordMage::SyllableTemplate.new("CV")
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "r", "t", "k", "d"], ["a", "e", "o"])
        .with_syllable_templates([cluster_template, regular_template])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
        .build
      
      # Generate many words and check for disallowed clusters
      20.times do
        word = generator.generate
        # Should not contain forbidden clusters like "pk", "pt", "rk", etc.
        word.should_not match(/pk|pt|rk|rt|kd|kp|kt|dp|dt|dk/)
      end
    end

    it "works with realistic Elvish clusters" do
      consonants = ["m", "l", "t", "r", "p", "k", "d", "z", "s", "θ"]
      vowels = ["a", "e", "i", "o", "u"]
      elvish_clusters = ["ml", "tr", "pr", "kr", "dr", "zr", "sp", "θr"]
      
      cluster_template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: elvish_clusters)
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(consonants, vowels)
        .with_syllable_templates([cluster_template])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .with_romanization({"θ" => "th"})
        .build
      
      50.times do
        word = generator.generate
        # Extract the cluster (first 2-3 characters depending on if it's "thr")
        if word.starts_with?("thr")
          cluster = "thr"  # Handle "θr" -> "thr" romanization
        elsif word.size >= 2
          cluster = word[0..1]  # Regular 2-char cluster
        else
          cluster = word[0..0]  # Single char fallback
        end
        
        # Should be one of our allowed clusters (accounting for romanization)
        romanized_clusters = ["ml", "tr", "pr", "kr", "dr", "zr", "sp", "thr"]
        romanized_clusters.should contain(cluster)
      end
    end
  end
end