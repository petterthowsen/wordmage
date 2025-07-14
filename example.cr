require "./src/wordmage"

# Example 1: Generate words starting with a vowel
puts "=== Words starting with vowels ==="
vowel_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k", "r"], ["a", "e", "i", "o"])
  .with_syllable_patterns(["V", "CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 3))
  .starting_with(:vowel)
  .build

5.times do
  puts vowel_gen.generate
end

# Example 2: Generate words of exactly 3 syllables
puts "\n=== Words with exactly 3 syllables ==="
three_syl_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k"], ["a", "e", "i"])
  .with_syllable_patterns(["CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(3))
  .build

5.times do
  puts three_syl_gen.generate
end

# Example 3: Generate words between 2 and 4 syllables
puts "\n=== Words with 2-4 syllables ==="
range_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "s"], ["a", "e", "o"])
  .with_syllable_patterns(["CV", "CVC"])
  .with_syllable_count(WordMage::SyllableCountSpec.range(2, 4))
  .build

5.times do
  word = range_gen.generate
  syllables = word.size / 2  # Rough estimate for CV patterns
  puts "#{word} (~#{syllables} syllables)"
end

# Example 4: Generate words with vowel-vowel sequences (hiatus)
puts "\n=== Words with vowel sequences (hiatus) ==="
hiatus_template = WordMage::SyllableTemplate.new("CV", hiatus_probability: 0.5_f32)
hiatus_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "r", "n"], ["a", "e", "i", "o"])
  .with_syllable_templates([hiatus_template])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .build

5.times do
  puts hiatus_gen.generate
end

# Example 5: Generate words with consonant clusters
puts "\n=== Words with consonant clusters ==="
cluster_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "r", "t", "s"], ["a", "e", "o"])
  .with_syllable_patterns(["CCV", "CV"])  # CCV creates clusters
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .build

5.times do
  puts cluster_gen.generate
end

# Example 6: Weighted sampling
puts "\n=== Words with weighted phonemes ==="
weighted_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "t", "k"], ["a", "e"])
  .with_weights({"p" => 5.0_f32, "t" => 2.0_f32, "k" => 0.5_f32, "a" => 3.0_f32, "e" => 1.0_f32})
  .with_syllable_patterns(["CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .build

puts "Generating 20 words (should see more 'p' and 'a' due to higher weights):"
results = weighted_gen.generate_batch(20)
puts results.join(", ")

# Example 7: Sequential generation
puts "\n=== Sequential generation ==="
sequential_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["r", "t"], ["a", "e"])
  .with_syllable_patterns(["CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(1))
  .sequential_mode(8)
  .build

puts "All possible CV combinations with r,t + a,e:"
words = [] of String
while word = sequential_gen.next_sequential
  words << word
end
puts words.join(", ")

# Example 8: Complex constraints
puts "\n=== Words with constraints (no double consonants) ==="
constrained_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["p", "r", "s", "t"], ["a", "e", "o"])
  .with_syllable_patterns(["CVC", "CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .with_constraints(["rr", "ss", "tt", "pp"])  # No double consonants
  .build

5.times do
  puts constrained_gen.generate
end