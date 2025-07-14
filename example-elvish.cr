require "./src/wordmage"

# Elvish Conlang Word Generator
# 
# This example demonstrates generating words for an Elvish-style constructed language
# with realistic phonological patterns and weighted distributions.

puts "=== Elvish Word Generator ==="
puts

# Define phoneme mappings (IPA -> Romanization)
romanization = {
  # Consonants  
  "b" => "b", "d" => "d", "f" => "f", "g" => "g", "k" => "k", "l" => "l", "m" => "m", 
  "n" => "n", "p" => "p", "r" => "r", "s" => "s", "t" => "t", 
  "v" => "v", "z" => "z",
  "ɲ" => "ny", "ʒ" => "j", "θ" => "th",
  
  # Vowels
  "i" => "i", "u" => "u", "y" => "y", 
  "ɑ" => "a", "ɔ" => "o", "ɛ" => "e"
}

# Define phoneme weights based on commonality
phoneme_weights = {
  # Very common
  "θ" => 3.0_f32, "y" => 3.0_f32, "ɑ" => 3.0_f32, "ɔ" => 3.0_f32,
  "d" => 3.0_f32, "r" => 3.0_f32, "n" => 3.0_f32, "s" => 3.0_f32, "z" => 3.0_f32,
  
  # Fairly common  
  "k" => 2.0_f32, "g" => 2.0_f32, "l" => 2.0_f32, "m" => 2.0_f32, 
  "p" => 2.0_f32, "t" => 2.0_f32, "i" => 2.0_f32,
  
  # Less common (default weight of 1.0 for others)
  "b" => 1.0_f32, "f" => 1.0_f32, "v" => 1.0_f32,
  "ɲ" => 1.0_f32, "ʒ" => 1.0_f32, "u" => 1.0_f32, "ɛ" => 1.0_f32
}

# Define your exact allowed clusters  
elvish_clusters = ["ml", "gl", "tr", "pr", "kr", "gr", "dr", "zr", "sp", "θr", "nd"]

# Create syllable templates with explicit cluster support
onset_clusters = ["ml", "gl", "tr", "pr", "kr", "gr", "dr", "zr", "sp", "θr"]
coda_clusters = ["nd"]

cluster_template = WordMage::SyllableTemplate.new("CCV", 
  allowed_clusters: onset_clusters,
  hiatus_probability: 0.2_f32
)

# Template for words with coda clusters like "and-", "end-"
coda_cluster_template = WordMage::SyllableTemplate.new("CVCC", 
  allowed_coda_clusters: coda_clusters,
  hiatus_probability: 0.1_f32
)

regular_template = WordMage::SyllableTemplate.new("CV", 
  hiatus_probability: 0.3_f32  # Higher chance for vowel sequences in simple syllables
)

complex_template = WordMage::SyllableTemplate.new("CVC", 
  hiatus_probability: 0.1_f32
)

# Create the unified Elvish generator with all syllable types
ae_hiatus_template = WordMage::SyllableTemplate.new("V", hiatus_probability: 0.6_f32)

elvish_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_weights(phoneme_weights)
  .with_syllable_templates([
    regular_template,       # CV patterns
    complex_template,       # CVC patterns  
    cluster_template,       # CCV with allowed onset clusters
    coda_cluster_template,  # CVCC with coda clusters like "nd"
    ae_hiatus_template      # V with high hiatus probability
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.weighted({
    2 => 2.0_f32,    # Common
    3 => 3.0_f32,    # Most common
    4 => 2.0_f32,    # Common  
    5 => 1.0_f32     # Rare, for names
  }))
  .with_romanization(romanization)
  .random_mode
  .build

puts "## Mixed Elvish Words (all types)"
puts "Regular words with clusters, hiatus, and varied syllable counts:"
15.times do |i|
  word = elvish_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\n## Vowel-initial Words"
puts "Using starting constraint with the same generator:"
10.times do |i|
  word = elvish_generator.generate(:vowel)
  puts "#{i + 1}. #{word}"
end

puts "\n## Short Words (2 syllables)"
puts "Perfect for common words:"
10.times do |i|
  word = elvish_generator.generate(2)
  puts "#{i + 1}. #{word}"
end

puts "\n## Traditional Elvish Names (4-5 syllables)"
puts "Longer, flowing names:"
8.times do |i|
  word = elvish_generator.generate(4, 5)  # 4-5 syllables
  # Capitalize first letter for proper names
  capitalized_name = word.capitalize
  puts "#{i + 1}. #{capitalized_name}"
end

puts "\n## Vowel-initial Names (3-4 syllables)"
puts "Elegant vowel-starting names:"
8.times do |i|
  syllables = Random.rand(3..4)
  word = elvish_generator.generate(syllables, :vowel)
  capitalized_name = word.capitalize
  puts "#{i + 1}. #{capitalized_name}"
end

puts "\n## Word Statistics"
puts "Generated using phonological rules:"
puts "• Very common: th, y, a, o, d, r, n, s, z"
puts "• Fairly common: k, g, l, m, p, t, i"
puts "• Allowed clusters: ml, gl, tr, pr, kr, gr, dr, zr, sp, thr, nd"
puts "• Common sequences: 'ae' hiatus, 'ya' combinations"
puts "• Common onset: 'tha-'"