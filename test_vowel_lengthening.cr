require "./src/wordmage"

# Test vowel lengthening (vowel doubling)
romanization = {
  "t" => "t", "n" => "n", "k" => "k", "r" => "r", "l" => "l", "s" => "s", "m" => "m",
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Vowel Lengthening (Vowel Doubling) ==="

# Generator with moderate vowel lengthening probability
lengthening_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .with_vowel_lengthening_probability(0.3_f32)  # 30% chance of vowel lengthening
  .random_mode
  .build

puts "\n10 words with 30% vowel lengthening probability:"
lengthened_count = 0
10.times do |i|
  word = lengthening_generator.generate
  puts "#{i + 1}. #{word}"
  
  # Count lengthened words (words with doubled vowels)
  if word.includes?("aa") || word.includes?("ee") || word.includes?("oo") || 
     word.includes?("ii")
    lengthened_count += 1
    puts "  -> Contains vowel lengthening!"
  end
end

puts "\nLengthened words: #{lengthened_count}/10"

puts "\nComparison - generator without vowel lengthening:"
normal_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .with_vowel_lengthening_probability(0.0_f32)  # No lengthening
  .random_mode
  .build

5.times do |i|
  word = normal_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\nCombining gemination and vowel lengthening:"
combined_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .with_gemination_probability(0.2_f32)  # 20% consonant doubling
  .with_vowel_lengthening_probability(0.2_f32)  # 20% vowel lengthening
  .random_mode
  .build

puts "\n5 words with both gemination and vowel lengthening:"
5.times do |i|
  word = combined_generator.generate
  puts "#{i + 1}. #{word}"
  
  gem_present = word.includes?("tt") || word.includes?("nn") || word.includes?("kk") || 
                word.includes?("rr") || word.includes?("ll") || word.includes?("ss") || 
                word.includes?("mm")
  
  length_present = word.includes?("aa") || word.includes?("ee") || word.includes?("oo") || 
                   word.includes?("ii")
  
  if gem_present
    puts "  -> Gemination!"
  end
  if length_present
    puts "  -> Vowel lengthening!"
  end
  if gem_present && length_present
    puts "  -> Both features!"
  end
end