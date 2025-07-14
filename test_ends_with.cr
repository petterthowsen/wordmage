require "./src/wordmage"

# Test ends_with constraint
romanization = {
  "a" => "a", "t" => "t", "h" => "h", "r" => "r", "o" => "o", "n" => "n",
  "b" => "b", "d" => "d", "g" => "g", "k" => "k", "l" => "l", "m" => "m", 
  "s" => "s", 
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Ends With Constraint ==="

# Generator with ends_with 'ath'
suffix_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["a", "t", "h", "r", "o", "n", "b", "d", "g", "k", "l", "m", "s"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .ending_with_sequence("ath")  # Force words to end with 'ath'
  .random_mode
  .build

puts "\n10 words ending with 'ath':"
10.times do |i|
  word = suffix_generator.generate
  puts "#{i + 1}. #{word}"
  
  # Quick validation check
  if !word.ends_with?("ath")
    puts "  ERROR: Word does not end with 'ath'"
  end
end

puts "\nComparison - generator without ends_with constraint:"
normal_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["a", "t", "h", "r", "o", "n", "b", "d", "g", "k", "l", "m", "s"], 
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

puts "\nTesting different suffix - 'on':"
on_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["a", "t", "h", "r", "o", "n", "b", "d", "g", "k", "l", "m", "s"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .ending_with_sequence("on")
  .random_mode
  .build

5.times do |i|
  word = on_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\nCombining constraints - starts with 'thr' and ends with 'on':"
combined_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["a", "t", "h", "r", "o", "n", "b", "d", "g", "k", "l", "m", "s"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(3, 4))
  .with_romanization(romanization)
  .starting_with_sequence("thr")
  .ending_with_sequence("on")
  .random_mode
  .build

3.times do |i|
  word = combined_generator.generate
  puts "#{i + 1}. #{word}"
end