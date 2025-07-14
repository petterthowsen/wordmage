require "./src/wordmage"

puts "=== Simple Custom Pattern Example ==="

# Simple generator with just one custom group
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
  .with_custom_group('F', ["f", "s"])
  .with_syllable_patterns(["FV"])  # Just fricative-vowel
  .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
  .build

puts "Generated words:"
5.times do |i|
  word = generator.generate
  puts "#{i + 1}. #{word}"
end