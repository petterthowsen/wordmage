require "./src/wordmage"

# Test gemination generation
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k", "r", "s"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .with_gemination_probability(1.0)  # 100% gemination
  .build

romanizer = WordMage::RomanizationMap.new({"t" => "t", "n" => "n", "k" => "k", "r" => "r", "s" => "s", "a" => "a", "e" => "e", "i" => "i", "o" => "o"})

puts "Testing gemination with 100% probability:"
puts "=" * 50

20.times do |i|
  word = generator.generate
  
  puts "\nWord #{i + 1}: #{word}"
  
  # Check for double consonants visually
  has_double_consonant = word.match(/([a-z])\1/)
  puts "  Visual check for doubles: #{has_double_consonant ? "YES" : "NO"}"
  
  # Use word analyzer
  analyzer = WordMage::WordAnalyzer.new(romanizer)
  analysis = analyzer.analyze(word)
  
  puts "  Gemination sequences detected: #{analysis.gemination_sequences.inspect}"
  puts "  Syllable count: #{analysis.syllable_count}"
end

puts "\n\n" + "=" * 50
puts "Testing vowel lengthening with 100% probability:"
puts "=" * 50

generator2 = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n", "k"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .with_vowel_lengthening_probability(1.0)  # 100% vowel lengthening
  .build

10.times do |i|
  word = generator2.generate
  puts "\nWord #{i + 1}: #{word}"
  
  # Check for double vowels visually
  has_double_vowel = word.match(/([aeiou])\1/)
  puts "  Visual check for doubles: #{has_double_vowel ? "YES" : "NO"}"
  
  # Use word analyzer
  analyzer = WordMage::WordAnalyzer.new(romanizer)
  analysis = analyzer.analyze(word)
  
  puts "  Vowel lengthening sequences detected: #{analysis.vowel_lengthening_sequences.inspect}"
  puts "  Syllable count: #{analysis.syllable_count}"
end
