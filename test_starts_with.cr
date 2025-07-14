require "./src/wordmage"

# Test starts_with constraint
romanization = {
  "t" => "t", "h" => "h", "r" => "r", "a" => "a",
  "b" => "b", "d" => "d", "g" => "g", "k" => "k", "l" => "l", "m" => "m", 
  "n" => "n", "s" => "s", 
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing Starts With Constraint ==="

# Generator with starts_with 'thra'
prefix_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "h", "r", "b", "d", "g", "k", "l", "m", "n", "s"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_romanization(romanization)
  .starting_with_sequence("thra")  # Force words to start with 'thra'
  .random_mode
  .build

puts "\n10 words starting with 'thra':"
10.times do |i|
  word = prefix_generator.generate
  puts "#{i + 1}. #{word}"
  
  # Quick validation check
  if !word.starts_with?("thra")
    puts "  ERROR: Word does not start with 'thra'"
  end
end

puts "\nComparison - generator without starts_with constraint:"
normal_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "h", "r", "b", "d", "g", "k", "l", "m", "n", "s"], 
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

puts "\nTesting different prefix - 'dr':"
dr_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "h", "r", "b", "d", "g", "k", "l", "m", "n", "s"], 
                 ["ɑ", "ɛ", "ɔ", "i"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .starting_with_sequence("dr")
  .random_mode
  .build

5.times do |i|
  word = dr_generator.generate
  puts "#{i + 1}. #{word}"
end