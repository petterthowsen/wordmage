require "./src/wordmage"

# Test analyzer detection with known gemination and lengthening patterns
romanization = {
  "t" => "t", "n" => "n", "k" => "k", "r" => "r", "l" => "l", "s" => "s", "m" => "m",
  "ɑ" => "a", "ɛ" => "e", "ɔ" => "o", "i" => "i"
}

puts "=== Testing WordAnalyzer Detection ==="

analyzer = WordMage::WordAnalyzer.new(WordMage::RomanizationMap.new(romanization))

# Test words with known patterns
test_words = [
  "tenna",     # gemination: nn
  "kaara",     # vowel lengthening: aa
  "silloot",   # both: ll and oo
  "normal",    # neither
  "mittaan"    # both: tt and aa
]

test_words.each do |word|
  analysis = analyzer.analyze(word)
  
  puts "\nWord: #{word}"
  puts "  Phonemes: #{analysis.phonemes.join(" ")}"
  puts "  Gemination sequences: #{analysis.gemination_sequences}"
  puts "  Vowel lengthening sequences: #{analysis.vowel_lengthening_sequences}"
  puts "  Has gemination: #{analysis.has_gemination?}"
  puts "  Has vowel lengthening: #{analysis.has_vowel_lengthening?}"
end

puts "\n=== Testing Aggregate Analysis ==="

# Test aggregate analysis
aggregate_analyzer = WordMage::Analyzer.new(WordMage::RomanizationMap.new(romanization))
analysis = aggregate_analyzer.analyze(test_words)

puts "\nAggregate analysis of words: #{test_words.join(", ")}"
puts "Gemination patterns: #{analysis.gemination_patterns}"
puts "Vowel lengthening patterns: #{analysis.vowel_lengthening_patterns}"