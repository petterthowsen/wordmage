require "./src/wordmage"

puts "=== Custom Pattern Elements Example ==="
puts

# Create a generator with custom phoneme groups
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "m", "n", "l", "r"], ["a", "e", "i", "o", "u"])
  .with_custom_group('F', ["f", "v", "s", "z", "ʃ", "ʒ"])  # Fricatives
  .with_custom_group('N', ["m", "n", "ŋ"])                 # Nasals  
  .with_custom_group('L', ["l", "r"])                      # Liquids
  .with_custom_group('H', ["a", "e"])                      # High vowels (vowel-like)
  .with_syllable_patterns([
    "CV",    # Standard consonant-vowel
    "CVC",   # Standard consonant-vowel-consonant
    "FVC",   # Fricative-vowel-consonant
    "CVN",   # Consonant-vowel-nasal
    "FVL",   # Fricative-vowel-liquid
    "NVF",   # Nasal-vowel-fricative
    "CVLF",  # Consonant-vowel-liquid-fricative
    "FVNL"   # Fricative-vowel-nasal-liquid
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .build

puts "Generated words using custom pattern elements:"
puts

20.times do |i|
  word = generator.generate
  puts "#{(i + 1).to_s.rjust(2)}. #{word}"
end

puts
puts "Custom groups defined:"
puts "F (Fricatives): #{generator.phoneme_set.get_custom_group('F')}"
puts "N (Nasals): #{generator.phoneme_set.get_custom_group('N')}"
puts "L (Liquids): #{generator.phoneme_set.get_custom_group('L')}"
puts "H (High vowels): #{generator.phoneme_set.get_custom_group('H')}"

puts
puts "Vowel-like groups:"
puts "H is vowel-like: #{generator.phoneme_set.is_vowel_like_group?('H')}"
puts "F is vowel-like: #{generator.phoneme_set.is_vowel_like_group?('F')}"
puts "N is vowel-like: #{generator.phoneme_set.is_vowel_like_group?('N')}"