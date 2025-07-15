require "./spec_helper"

describe WordMage::GeneratorBuilder do
  describe ".create" do
    it "creates a new builder instance" do
      builder = WordMage::GeneratorBuilder.create
      builder.should be_a(WordMage::GeneratorBuilder)
    end
  end

  describe "#with_phonemes" do
    it "sets consonants and vowels" do
      consonants = ["p", "t", "k"]
      vowels = ["a", "e", "i"]
      
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(consonants, vowels)
      
      # We can't directly test internal state, but we can build and verify
      generator = builder
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      generator.phoneme_set.consonant_symbols.should eq(consonants.to_set)
      generator.phoneme_set.vowel_symbols.should eq(vowels.to_set)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
      result = builder.with_phonemes(["p"], ["a"])
      
      result.should be(builder)
    end
  end

  describe "#with_weights" do
    it "sets phoneme weights" do
      weights = {"p" => 2.0_f32, "a" => 1.5_f32}
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a", "e"])
        .with_weights(weights)
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      generator.phoneme_set.symbol_weights.should eq(weights)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
      result = builder.with_weights({"p" => 1.0_f32})
      
      result.should be(builder)
    end
  end

  describe "#with_syllable_patterns" do
    it "creates syllable templates from patterns" do
      patterns = ["CV", "CVC", "CCV"]
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a", "e"])
        .with_syllable_patterns(patterns)
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      generator.word_spec.syllable_templates.size.should eq(3)
      generator.word_spec.syllable_templates.map(&.pattern).should eq(patterns)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
      result = builder.with_syllable_patterns(["CV"])
      
      result.should be(builder)
    end
  end

  describe "#with_syllable_pattern_probabilities" do
    it "creates syllable templates with custom probabilities" do
      patterns_with_probabilities = {"CV" => 3.0_f32, "CVC" => 1.5_f32, "CCV" => 0.5_f32}
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a", "e"])
        .with_syllable_pattern_probabilities(patterns_with_probabilities)
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      templates = generator.word_spec.syllable_templates
      templates.size.should eq(3)
      
      # Check that probabilities were set correctly
      cv_template = templates.find { |t| t.pattern == "CV" }.not_nil!
      cvc_template = templates.find { |t| t.pattern == "CVC" }.not_nil!
      ccv_template = templates.find { |t| t.pattern == "CCV" }.not_nil!
      
      cv_template.probability.should eq(3.0_f32)
      cvc_template.probability.should eq(1.5_f32)
      ccv_template.probability.should eq(0.5_f32)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
      result = builder.with_syllable_pattern_probabilities({"CV" => 1.0_f32})
      
      result.should be(builder)
    end
  end

  describe "#with_syllable_count" do
    it "sets the syllable count specification" do
      spec = WordMage::SyllableCountSpec.range(2, 4)
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(spec)
        .build
      
      generator.word_spec.syllable_count.should eq(spec)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
      result = builder.with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      
      result.should be(builder)
    end
  end

  describe "#starting_with" do
    it "sets the starting phoneme type" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV", "V"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .starting_with(:vowel)
        .build
      
      generator.word_spec.starting_type.should eq(:vowel)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      result = builder.starting_with(:consonant)
      
      result.should be(builder)
    end
  end

  describe "#with_constraints" do
    it "sets word-level constraints" do
      constraints = ["rr", "ss", "tt"]
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "r", "s"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
        .with_constraints(constraints)
        .build
      
      generator.word_spec.word_constraints.should eq(constraints)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      result = builder.with_constraints(["rr"])
      
      result.should be(builder)
    end
  end

  describe "#with_romanization" do
    it "sets up romanization mappings" do
      mappings = {"p" => "ph", "t" => "th", "a" => "a"}
      
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .with_romanization(mappings)
        .build
      
      generator.romanizer.mappings.should eq(mappings)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      result = builder.with_romanization({"p" => "ph"})
      
      result.should be(builder)
    end
  end

  describe "#sequential_mode" do
    it "sets sequential generation mode" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .sequential_mode(100)
        .build
      
      generator.mode.should eq(WordMage::GenerationMode::Sequential)
      generator.max_words.should eq(100)
    end

    it "uses default max_words when not specified" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .sequential_mode
        .build
      
      generator.mode.should eq(WordMage::GenerationMode::Sequential)
      generator.max_words.should eq(1000)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      result = builder.sequential_mode
      
      result.should be(builder)
    end
  end

  describe "#random_mode" do
    it "sets random generation mode" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .random_mode
        .build
      
      generator.mode.should eq(WordMage::GenerationMode::Random)
    end

    it "returns self for fluent chaining" do
      builder = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
      result = builder.random_mode
      
      result.should be(builder)
    end
  end

  describe "#build" do
    it "creates a complete generator" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
        .with_syllable_patterns(["CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.range(1, 3))
        .with_romanization({"p" => "p", "t" => "t", "k" => "k", "a" => "a", "e" => "e", "i" => "i"})
        .random_mode
        .build
      
      generator.should be_a(WordMage::Generator)
      generator.mode.should eq(WordMage::GenerationMode::Random)
      
      # Should be able to generate words
      word = generator.generate
      word.should be_a(String)
      word.size.should be > 0
    end

    it "uses default values for optional parameters" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p"], ["a"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      generator.word_spec.starting_type.should be_nil
      generator.word_spec.word_constraints.should eq([] of String)
      generator.romanizer.mappings.should eq({} of String => String)
      generator.mode.should eq(WordMage::GenerationMode::Random)
    end
  end

  describe "integration tests" do
    it "builds generator for vowel-initial words" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
        .with_syllable_patterns(["V", "CV", "CVC"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
        .starting_with(:vowel)
        .build
      
      word = generator.generate
      first_char = word[0].to_s
      generator.phoneme_set.is_vowel?(first_char).should be_true
    end

    it "builds generator for sequential mode" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["r", "t"], ["a", "e"])
        .with_syllable_patterns(["CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .sequential_mode(8)
        .build
      
      words = [] of String
      while word = generator.next_sequential
        words << word
      end
      
      # Should generate combinations in order
      expected = ["ra", "re", "ta", "te"]
      expected.each do |expected_word|
        words.should contain(expected_word)
      end
    end

    it "builds generator with weighted phonemes" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "t"], ["a", "e"])
        .with_weights({"p" => 10.0_f32, "t" => 0.1_f32})
        .with_syllable_patterns(["C"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
        .build
      
      # Generate many words and verify weighting
      results = (1..50).map { generator.generate }
      p_count = results.count("p")
      t_count = results.count("t")
      
      # "p" should appear much more often than "t"
      p_count.should be > t_count
    end

    it "builds generator with complex constraints" do
      generator = WordMage::GeneratorBuilder.create
        .with_phonemes(["p", "r", "s"], ["a", "e", "o"])
        .with_syllable_patterns(["CCV", "CV"])
        .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
        .with_constraints(["rr", "ss"])
        .build
      
      # Generate multiple words and verify no double consonants
      10.times do
        word = generator.generate
        word.should_not match(/rr|ss/)
      end
    end
  end
end