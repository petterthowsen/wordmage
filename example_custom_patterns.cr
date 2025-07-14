require "./src/wordmage"

puts "=== Custom Pattern Elements Example ==="
puts

# Create a generator with custom phoneme groups and romanization
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "m", "n", "l", "r"], ["a", "e", "i", "o", "u"])
  .with_custom_group('F', ["f", "v", "s", "z", "ʃ", "ʒ"])  # Fricatives
  .with_custom_group('N', ["m", "n", "ŋ"])                 # Nasals  
  .with_custom_group('L', ["l", "r"])                      # Liquids
  .with_custom_group('H', ["a", "e"])                      # High vowels (vowel-like)
  .with_romanization({
    # Standard phonemes
    "p" => "p", "t" => "t", "k" => "k", "m" => "m", "n" => "n", "l" => "l", "r" => "r",
    "a" => "a", "e" => "e", "i" => "i", "o" => "o", "u" => "u",
    # Special phonemes
    "ʃ" => "sh", "ʒ" => "zh", "ŋ" => "ng",
    # Add any other mappings needed
    "f" => "f", "v" => "v", "s" => "s", "z" => "z"
  })
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
  # Generate a word in phonemic form
  phonemic_word = generator.generate
  
  # Get the romanized form using the generator's romanizer
  phonemes = phonemic_word.chars.map(&.to_s)
  romanized_word = generator.romanizer.romanize(phonemes)
  
  puts "#{(i + 1).to_s.rjust(2)} | #{phonemic_word.ljust(15)} | #{romanized_word}"
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