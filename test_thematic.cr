require "./src/wordmage"

# Test thematic vowel constraint
romanization = {
  "b" => "b", "d" => "d", "g" => "g", "k" => "k", "l" => "l", "m" => "m", 
  "n" => "n", "r" => "r", "s" => "s", "t" => "t", 
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Thematic Vowel Constraint ==="

# Generator with thematic vowel 'a' 
thematic_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "g", "k", "l", "m", "n", "r", "s", "t"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .with_thematic_vowel("ɑ")  # Force last vowel to be 'a'
  .random_mode
  .build

puts "\n10 words with thematic vowel 'a' (should all end with 'a' as last vowel):"
10.times do |i|
  word = thematic_generator.generate
  puts "#{i + 1}. #{word}"
  
  # Quick validation check
  phonemes = word.split("").map { |char| 
    romanization.key_for?(char) || char 
  }.reject(&.empty?)
  
  # Find last vowel
  vowels = ["ɑ", "ɛ", "ɔ", "i"]
  last_vowel = nil
  phonemes.reverse_each do |phoneme|
    if vowels.includes?(phoneme)
      last_vowel = phoneme
      break
    end
  end
  
  if last_vowel != "ɑ"
    puts "  ERROR: Last vowel is '#{last_vowel}', expected 'ɑ'"
  end
end

puts "\nComparison - generator without thematic vowel:"
normal_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "g", "k", "l", "m", "n", "r", "s", "t"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .random_mode
  .build

5.times do |i|
  word = normal_generator.generate
  puts "#{i + 1}. #{word}"
end