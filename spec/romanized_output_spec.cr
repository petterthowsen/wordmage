require "./spec_helper"

# Helper to create a generator similar to the example-elvish setup
private def build_elvish_generator(hiatus : Float32, disable_hiatus : Bool = false) : WordMage::Generator
  romanization = {
    "b" => "b", "d" => "d", "f" => "f", "g" => "g", "k" => "k", "l" => "l", "m" => "m",
    "n" => "n", "p" => "p", "r" => "r", "s" => "s", "t" => "t",
    "v" => "v", "z" => "z",
    "ɲ" => "ny", "ʒ" => "j", "θ" => "th",
    "i" => "i", "u" => "u", "y" => "y",
    "ɑ" => "a", "ɔ" => "o", "ɛ" => "e"
  }

  consonants = ["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"]
  vowels = ["i", "u", "y", "ɑ", "ɔ", "ɛ"]
  onset_clusters = ["tr", "gr", "thr", "dr"]
  coda_clusters = ["n", "s", "r"]

  hp = disable_hiatus ? 0.0_f32 : hiatus

  cluster_template = WordMage::SyllableTemplate.new("CCV", allowed_clusters: onset_clusters, hiatus_probability: hp)
  coda_template = WordMage::SyllableTemplate.new("CVC", allowed_coda_clusters: coda_clusters, hiatus_probability: hp)
  regular_template = WordMage::SyllableTemplate.new("CV", hiatus_probability: hp)
  vowel_template = WordMage::SyllableTemplate.new("V", hiatus_probability: hp)

  templates = [regular_template, cluster_template, coda_template]
  templates.unshift(vowel_template) unless disable_hiatus

  WordMage::GeneratorBuilder.create
    .with_phonemes(consonants, vowels)
    .with_syllable_templates(templates)
    .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
    .with_romanization(romanization)
    .with_vowel_lengthening_probability(0.0_f32)
    .random_mode
    .build
end

describe "Romanized Generator Output" do
  it "romanizes all output" do
    generator = build_elvish_generator(0.2_f32)
    analyzer = WordMage::WordAnalyzer.new(generator.romanizer)

    20.times do
      word = generator.generate
      # Ensure no raw IPA symbols appear in output
      word.should_not match(/[ɲʒθɑɔɛ]/)
      # Re-romanize analyzed phonemes and compare
      analysis = analyzer.analyze(word)
      generator.romanizer.romanize(analysis.phonemes).should eq(word)
    end
  end

  it "respects syllable range" do
    generator = build_elvish_generator(0.2_f32)
    analyzer = WordMage::WordAnalyzer.new(generator.romanizer)

    20.times do
      analysis = nil
      5.times do
        word = generator.generate(2, 4)
        analysis = analyzer.analyze(word)
        break if analysis.syllable_count >= 2 && analysis.syllable_count <= 4
      end
      valid_analysis = analysis.not_nil!
      valid_analysis.syllable_count.should be >= 2
      valid_analysis.syllable_count.should be <= 4
    end
  end

  it "generates hiatus without duplicates when enabled" do
    generator = build_elvish_generator(1.0_f32)
    analyzer = WordMage::WordAnalyzer.new(generator.romanizer)

    10.times do
      analysis = nil
      5.times do
        word = generator.generate(3)
        analysis = analyzer.analyze(word)
        break if analysis.syllable_count == 3
      end
      valid_analysis = analysis.not_nil!
      valid_analysis.syllable_count.should eq(3)
      valid_analysis.vowel_lengthening_sequences.should be_empty
      valid_analysis.hiatus_sequences.each do |seq|
        seq.size.should be <= 2
        (0...seq.size-1).each do |i|
          seq[i].should_not eq(seq[i+1])
        end
      end
    end
  end

  it "produces no hiatus when disabled" do
    generator = build_elvish_generator(0.2_f32, disable_hiatus: true)
    analyzer = WordMage::WordAnalyzer.new(generator.romanizer)

    10.times do
      word = generator.generate(3)
      analysis = analyzer.analyze(word)
      analysis.hiatus_count.should eq(0)
    end
  end
end

