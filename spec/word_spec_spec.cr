require "./spec_helper"

describe WordMage::SyllableCountSpec do
  describe ".exact" do
    it "creates an exact syllable count spec" do
      spec = WordMage::SyllableCountSpec.exact(3)
      spec.type.should eq(WordMage::SyllableCountSpec::Type::Exact)
      spec.min.should eq(3)
      spec.max.should eq(3)
    end
  end

  describe ".range" do
    it "creates a range syllable count spec" do
      spec = WordMage::SyllableCountSpec.range(2, 4)
      spec.type.should eq(WordMage::SyllableCountSpec::Type::Range)
      spec.min.should eq(2)
      spec.max.should eq(4)
    end
  end

  describe ".weighted" do
    it "creates a weighted syllable count spec" do
      weights = {2 => 1.0_f32, 3 => 2.0_f32, 4 => 1.0_f32}
      spec = WordMage::SyllableCountSpec.weighted(weights)
      spec.type.should eq(WordMage::SyllableCountSpec::Type::Weighted)
      spec.weights.should eq(weights)
    end
  end

  describe "#generate_count" do
    it "returns exact count for exact type" do
      spec = WordMage::SyllableCountSpec.exact(3)
      10.times do
        spec.generate_count.should eq(3)
      end
    end

    it "returns count within range for range type" do
      spec = WordMage::SyllableCountSpec.range(2, 4)
      10.times do
        count = spec.generate_count
        count.should be >= 2
        count.should be <= 4
      end
    end

    it "returns weighted count for weighted type" do
      # Weight 3 syllables much higher than others
      weights = {2 => 0.1_f32, 3 => 10.0_f32, 4 => 0.1_f32}
      spec = WordMage::SyllableCountSpec.weighted(weights)
      
      # Generate many counts and verify 3 appears most often
      results = (1..100).map { spec.generate_count }
      three_count = results.count(3)
      
      # Should be heavily weighted toward 3
      three_count.should be > 50
    end
  end
end

describe WordMage::WordSpec do
  describe "#initialize" do
    it "creates a word spec with all parameters" do
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      constraints = ["rr", "ss"]
      
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        starting_type: :vowel,
        syllable_templates: templates,
        word_constraints: constraints
      )
      
      word_spec.syllable_count.should eq(syllable_count)
      word_spec.starting_type.should eq(:vowel)
      word_spec.syllable_templates.should eq(templates)
      word_spec.word_constraints.should eq(constraints)
    end

    it "creates a word spec with optional parameters" do
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates
      )
      
      word_spec.starting_type.should be_nil
      word_spec.word_constraints.should eq([] of String)
    end
  end

  describe "#generate_syllable_count" do
    it "delegates to syllable count spec" do
      syllable_count = WordMage::SyllableCountSpec.exact(3)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      word_spec.generate_syllable_count.should eq(3)
    end
  end

  describe "#select_template" do
    it "selects a template for the given position" do
      templates = [
        WordMage::SyllableTemplate.new("CV"),
        WordMage::SyllableTemplate.new("CVC")
      ]
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      template = word_spec.select_template(:initial)
      templates.should contain(template)
    end

    it "respects position weights when present" do
      template1 = WordMage::SyllableTemplate.new("CV", position_weights: {:initial => 10.0_f32})
      template2 = WordMage::SyllableTemplate.new("CVC", position_weights: {:initial => 0.1_f32})
      templates = [template1, template2]
      
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      # With these weights, template1 should be selected much more often for :initial
      results = (1..50).map { word_spec.select_template(:initial) }
      template1_count = results.count(template1)
      
      template1_count.should be > 25  # Should be heavily weighted toward template1
    end

    it "respects template probabilities when no position weights" do
      template1 = WordMage::SyllableTemplate.new("CV", probability: 5.0_f32)
      template2 = WordMage::SyllableTemplate.new("CVC", probability: 1.0_f32)
      templates = [template1, template2]
      
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      # With these probabilities, template1 should be selected much more often
      results = (1..100).map { word_spec.select_template(:initial) }
      template1_count = results.count(template1)
      
      template1_count.should be > 60  # Should be heavily weighted toward template1
    end

    it "combines template probability with position weights" do
      template1 = WordMage::SyllableTemplate.new("CV", probability: 2.0_f32, position_weights: {:initial => 3.0_f32})
      template2 = WordMage::SyllableTemplate.new("CVC", probability: 1.0_f32, position_weights: {:initial => 1.0_f32})
      templates = [template1, template2]
      
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      # Combined weight: template1 = 2.0 * 3.0 = 6.0, template2 = 1.0 * 1.0 = 1.0
      results = (1..100).map { word_spec.select_template(:initial) }
      template1_count = results.count(template1)
      
      template1_count.should be > 70  # Should be heavily weighted toward template1
    end
  end

  describe "#validate_word" do
    it "validates word against constraints" do
      constraints = ["rr", "tt"]
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(
        syllable_count: syllable_count,
        syllable_templates: templates,
        word_constraints: constraints
      )
      
      # Valid word
      word_spec.validate_word(["t", "a", "p", "a"]).should be_true
      
      # Invalid word (contains "rr")
      word_spec.validate_word(["r", "r", "a"]).should be_false
      
      # Invalid word (contains "tt")
      word_spec.validate_word(["t", "t", "a"]).should be_false
    end

    it "returns true when no constraints" do
      syllable_count = WordMage::SyllableCountSpec.exact(2)
      templates = [WordMage::SyllableTemplate.new("CV")]
      word_spec = WordMage::WordSpec.new(syllable_count: syllable_count, syllable_templates: templates)
      
      word_spec.validate_word(["r", "r", "a"]).should be_true
    end
  end
end