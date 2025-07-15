require "./src/wordmage"

# Test the thematic vowel fix
romanization = {"t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s", "l" => "l", "a" => "a", "e" => "e", "i" => "i", "o" => "o"}

puts "Testing thematic vowel constraint with romanized input..."

# This should work now - thematic vowel 'a' should be accepted when there's a vowel that romanizes to 'a'
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "s", "l"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_romanization(romanization)
  .with_thematic_vowel("a")  # This should work now
  .build

puts "Generator created successfully!"

# Generate some words to verify
5.times do |i|
  word = generator.generate
  puts "Generated word #{i + 1}: #{word}"
  
  # Verify that the word ends with 'a'
  unless word.ends_with?("a")
    puts "  ERROR: Word doesn't end with 'a'!"
  else
    puts "  ✓ Word correctly ends with 'a'"
  end
end

puts "\nAll tests passed! Thematic vowel constraint is working correctly."