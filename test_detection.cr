require "./src/wordmage"

# Test detection of gemination and vowel lengthening
romanization = {
  "t" => "t", "n" => "n", "k" => "k", "r" => "r", "l" => "l", "s" => "s", "m" => "m",
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Gemination and Vowel Lengthening Detection ==="

# Create generator with both features enabled
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .with_gemination_probability(0.5_f32)  # 50% chance
  .with_vowel_lengthening_probability(0.5_f32)  # 50% chance
  .random_mode
  .build

# Create analyzer to test detection
analyzer = WordMage::Analyzer.new(WordMage::RomanizationMap.new(romanization))

puts "\nGenerating and analyzing 10 words:"

gem_detected = 0
length_detected = 0

10.times do |i|
  word = generator.generate
  analysis = analyzer.analyze([word])
  
  puts "#{i + 1}. #{word}"
  
  # Check if word has gemination (doubled consonants)
  has_gem = word.includes?("tt") || word.includes?("nn") || word.includes?("kk") || 
            word.includes?("rr") || word.includes?("ll") || word.includes?("ss") || 
            word.includes?("mm")
  
  # Check if word has vowel lengthening (doubled vowels)
  has_length = word.includes?("aa") || word.includes?("ee") || word.includes?("oo") || 
               word.includes?("ii")
  
  if has_gem
    gem_detected += 1
    puts "  -> Gemination present: #{analysis.gemination_patterns.keys}"
  end
  
  if has_length
    length_detected += 1
    puts "  -> Vowel lengthening present: #{analysis.vowel_lengthening_patterns.keys}"
  end
end

puts "\nDetection summary:"
puts "Words with gemination: #{gem_detected}/10"
puts "Words with vowel lengthening: #{length_detected}/10"

puts "\nTesting convenience methods:"

# Test enable methods
enabled_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .enable_gemination
  .enable_vowel_lengthening
  .random_mode
  .build

puts "\nWith enable_gemination and enable_vowel_lengthening:"
3.times do |i|
  word = enabled_generator.generate
  puts "#{i + 1}. #{word}"
end

# Test disable methods
disabled_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "l", "s", "m"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .disable_gemination
  .disable_vowel_lengthening
  .random_mode
  .build

puts "\nWith disable_gemination and disable_vowel_lengthening:"
3.times do |i|
  word = disabled_generator.generate
  puts "#{i + 1}. #{word}"
end