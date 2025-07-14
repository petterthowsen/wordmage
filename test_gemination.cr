require "./src/wordmage"

# Test gemination (consonant doubling)
romanization = {
  "t" => "t", "n" => "n", "k" => "k", "r" => "r", "l" => "l", "s" => "s", "m" => "m",
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Gemination (Consonant Doubling) ==="

# Generator with high gemination probability
gemination_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .with_gemination_probability(0.3_f32)  # 30% chance of consonant doubling
  .random_mode
  .build

puts "\n10 words with 30% gemination probability:"
geminated_count = 0
10.times do |i|
  word = gemination_generator.generate
  puts "#{i + 1}. #{word}"
  
  # Count geminated words (words with doubled consonants)
  if word.includes?("tt") || word.includes?("nn") || word.includes?("kk") || 
     word.includes?("rr") || word.includes?("ll") || word.includes?("ss") || 
     word.includes?("mm")
    geminated_count += 1
    puts "  -> Contains gemination!"
  end
end

puts "\nGeminated words: #{geminated_count}/10"

puts "\nComparison - generator without gemination:"
normal_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .with_gemination_probability(0.0_f32)  # No gemination
  .random_mode
  .build

5.times do |i|
  word = normal_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\nTesting very high gemination (70%):"
high_gem_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .with_gemination_probability(0.7_f32)  # 70% chance
  .random_mode
  .build

high_geminated_count = 0
5.times do |i|
  word = high_gem_generator.generate
  puts "#{i + 1}. #{word}"
  
  if word.includes?("tt") || word.includes?("nn") || word.includes?("kk") || 
     word.includes?("rr") || word.includes?("ll") || word.includes?("ss") || 
     word.includes?("mm")
    high_geminated_count += 1
    puts "  -> Contains gemination!"
  end
end

puts "\nHigh gemination words: #{high_geminated_count}/5"