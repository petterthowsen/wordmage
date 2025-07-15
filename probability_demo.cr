require "./src/wordmage"

# Demo: SyllableTemplate Probability Feature
# This demonstrates how syllable templates can have custom probabilities
# to control how often different patterns are selected during generation.

puts "WordMage SyllableTemplate Probability Demo"
puts "=" * 50

# Basic setup
consonants = ["p", "t", "k", "r", "l", "s"]
vowels = ["a", "e", "i", "o"]
romanization = {
  "p" => "p", "t" => "t", "k" => "k", "r" => "r", "l" => "l", "s" => "s",
  "a" => "a", "e" => "e", "i" => "i", "o" => "o"
}

# Demo 1: Default probabilities (all equal)
puts "\n1. Default probabilities (all templates equally likely):"
generator1 = WordMage::GeneratorBuilder.create
  .with_phonemes(consonants, vowels)
  .with_syllable_patterns(["CV", "CVC", "CCV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .with_romanization(romanization)
  .build

words1 = (1..20).map { generator1.generate }
puts "Generated words: #{words1.join(", ")}"

# Demo 2: Custom probabilities favoring CV patterns
puts "\n2. Custom probabilities (CV: 5.0, CVC: 2.0, CCV: 0.5):"
generator2 = WordMage::GeneratorBuilder.create
  .with_phonemes(consonants, vowels)
  .with_syllable_pattern_probabilities({
    "CV" => 5.0_f32,   # Much more likely
    "CVC" => 2.0_f32,  # Somewhat likely
    "CCV" => 0.5_f32   # Less likely
  })
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .with_romanization(romanization)
  .build

words2 = (1..20).map { generator2.generate }
puts "Generated words: #{words2.join(", ")}"

# Demo 3: Statistical analysis
puts "\n3. Statistical analysis (100 words each):"

# Count syllable patterns in default generator
pattern_counts1 = {"CV" => 0, "CVC" => 0, "CCV" => 0, "Other" => 0}
100.times do
  word = generator1.generate
  if word.size == 4 && word[1] =~ /[aeiou]/ && word[3] =~ /[aeiou]/
    pattern_counts1["CV"] += 1
  elsif word.size == 6 && word[1] =~ /[aeiou]/ && word[4] =~ /[aeiou]/
    pattern_counts1["CVC"] += 1
  elsif word.size == 6 && word[2] =~ /[aeiou]/ && word[5] =~ /[aeiou]/
    pattern_counts1["CCV"] += 1
  else
    pattern_counts1["Other"] += 1
  end
end

# Count syllable patterns in probability-weighted generator
pattern_counts2 = {"CV" => 0, "CVC" => 0, "CCV" => 0, "Other" => 0}
100.times do
  word = generator2.generate
  if word.size == 4 && word[1] =~ /[aeiou]/ && word[3] =~ /[aeiou]/
    pattern_counts2["CV"] += 1
  elsif word.size == 6 && word[1] =~ /[aeiou]/ && word[4] =~ /[aeiou]/
    pattern_counts2["CVC"] += 1
  elsif word.size == 6 && word[2] =~ /[aeiou]/ && word[5] =~ /[aeiou]/
    pattern_counts2["CCV"] += 1
  else
    pattern_counts2["Other"] += 1
  end
end

puts "\nDefault probabilities distribution:"
pattern_counts1.each { |pattern, count| puts "  #{pattern}: #{count}%" }

puts "\nCustom probabilities distribution:"
pattern_counts2.each { |pattern, count| puts "  #{pattern}: #{count}%" }

puts "\nAs you can see, the custom probabilities significantly change"
puts "the distribution of syllable patterns in generated words!"
puts "\nThe probability feature allows you to create languages with"
puts "preferred syllable structures, making them sound more natural."