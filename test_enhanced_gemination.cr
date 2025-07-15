require "./src/wordmage"

# Test enhanced gemination system
puts "=== Testing Enhanced Gemination System ==="

romanization = WordMage::RomanizationMap.new({
  "g" => "g", "r" => "r", "a" => "a", "n" => "n", "e" => "e", "o" => "o", "t" => "t", "h" => "h"
})

# Test words with gemination patterns
words = ["aggon", "aggonya", "aggorim", "thaggor", "naggar", "ragger", "bigger", "sogger"]

puts "Analyzing words with gemination: #{words.join(", ")}"

analyzer = WordMage::Analyzer.new(romanization)
analysis = analyzer.analyze(words)

puts "\nDetected gemination patterns:"
analysis.gemination_patterns.each do |pattern, frequency|
  puts "  #{pattern}: #{(frequency * 100).round(1)}%"
end

# Test WITHOUT gemination probability (should have no gemination)
puts "\n=== Without Gemination Probability ==="
generator_no_gem = WordMage::GeneratorBuilder.create
  .with_phonemes(["g", "r", "n", "t", "h"], ["a", "e", "o"])
  .with_syllable_patterns(["CV", "CVC", "CCV"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization.mappings)
  .with_analysis_of_words(words, analysis_weight_factor: 10.0_f32)
  .with_gemination_probability(0.0_f32)  # No gemination
  .build

puts "Generator gemination patterns: #{generator_no_gem.gemination_patterns.size} entries"
puts "Generator gemination probability: #{generator_no_gem.gemination_probability}"

gem_count_no_prob = 0
10.times do |i|
  word = generator_no_gem.generate
  gem_count_no_prob += 1 if word.includes?("gg")
  print "#{word} "
end
puts "\nWords with 'gg': #{gem_count_no_prob}/10"

# Test WITH gemination probability as global multiplier
puts "\n=== With Gemination Probability as Global Multiplier ==="
generator_with_gem = WordMage::GeneratorBuilder.create
  .with_phonemes(["g", "r", "n", "t", "h"], ["a", "e", "o"])
  .with_syllable_patterns(["CV", "CVC", "CCV"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization.mappings)
  .with_analysis_of_words(words, analysis_weight_factor: 10.0_f32)
  .with_gemination_probability(0.3_f32)  # 30% base probability
  .build

puts "Generator gemination patterns: #{generator_with_gem.gemination_patterns.size} entries"
puts "Generator gemination probability: #{generator_with_gem.gemination_probability}"

gem_count_with_prob = 0
10.times do |i|
  word = generator_with_gem.generate
  gem_count_with_prob += 1 if word.includes?("gg")
  print "#{word} "
end
puts "\nWords with 'gg': #{gem_count_with_prob}/10"

puts "\nImprovement: #{gem_count_with_prob - gem_count_no_prob} more words with gemination"
puts "Expected: 'gg' should be more common than other geminates due to analysis patterns"