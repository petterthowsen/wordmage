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

# Define phoneme weights for more elegant words
phoneme_weights = {
  # Most common - flowing sounds
  "ɑ" => 4.0_f32, "ɛ" => 3.5_f32, "ɔ" => 3.0_f32,  # a, e, o
  "r" => 3.5_f32, "l" => 3.0_f32, "n" => 3.0_f32, "m" => 2.5_f32,  # liquids/nasals
  "s" => 3.0_f32, "θ" => 2.5_f32,  # fricatives
  
  # Common consonants
  "d" => 2.5_f32, "t" => 2.5_f32, "g" => 2.0_f32, "k" => 2.0_f32,
  "z" => 2.0_f32, "y" => 2.0_f32, "i" => 2.5_f32,
  
  # Less common - avoid overuse
  "p" => 1.5_f32, "b" => 1.0_f32, "f" => 1.0_f32, "v" => 1.0_f32,
  "ɲ" => 0.5_f32, "ʒ" => 0.5_f32, "u" => 1.5_f32  # reduce harsh sounds
}

# Simplified clusters for more elegant words
onset_clusters = ["tr", "gr", "θr", "dr"]  # Keep only the most flowing clusters
coda_clusters = ["n", "s", "r"]  # Simple codas instead of complex clusters

# Simplified syllable templates for more elegant words
cluster_template = WordMage::SyllableTemplate.new("CCV", 
  allowed_clusters: onset_clusters,
  hiatus_probability: 0.15_f32  # Reduced hiatus
)

# Simple coda template - single consonant endings
coda_template = WordMage::SyllableTemplate.new("CVC", 
  allowed_coda_clusters: coda_clusters,
  hiatus_probability: 0.1_f32
)

# Main CV template - most common pattern
regular_template = WordMage::SyllableTemplate.new("CV", 
  hiatus_probability: 0.2_f32  # Moderate hiatus for flow
)

# Vowel template for elegant transitions
vowel_template = WordMage::SyllableTemplate.new("V", hiatus_probability: 0.4_f32)

# Create generators with different complexity budgets
simple_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_weights(phoneme_weights)
  .with_syllable_templates([
    regular_template,       # CV patterns - most common
    vowel_template,         # V patterns for flow
    cluster_template,       # CCV with flowing onset clusters
    coda_template          # CVC with simple codas
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.weighted({
    2 => 3.0_f32,    # Most common for elegant words
    3 => 4.0_f32,    # Very common
    4 => 2.0_f32,    # Less common  
    5 => 1.0_f32     # Rare, for long names
  }))
  .with_romanization(romanization)
  .with_complexity_budget(5)  # Simple, melodic words
  .with_hiatus_escalation(2.0_f32)  # Discourage multiple hiatus
  .random_mode
  .build

medium_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_weights(phoneme_weights)
  .with_syllable_templates([
    regular_template, vowel_template, cluster_template, coda_template
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.weighted({
    2 => 3.0_f32, 3 => 4.0_f32, 4 => 2.0_f32, 5 => 1.0_f32
  }))
  .with_romanization(romanization)
  .with_complexity_budget(8)  # Moderate complexity
  .random_mode
  .build

complex_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_weights(phoneme_weights)
  .with_syllable_templates([
    regular_template, vowel_template, cluster_template, coda_template
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.weighted({
    2 => 3.0_f32, 3 => 4.0_f32, 4 => 2.0_f32, 5 => 1.0_f32
  }))
  .with_romanization(romanization)
  .with_complexity_budget(12)  # Complex words
  .random_mode
  .build

puts "## Simple & Melodic Words (Budget: 5)"
puts "Flowing, easy-to-pronounce words like 'andrasy', 'nazagon':"
10.times do |i|
  word = simple_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\n## Medium Complexity Words (Budget: 8)"
puts "Balanced words with some clusters and complexity:"
10.times do |i|
  word = medium_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\n## Complex Words (Budget: 12)"
puts "Words with clusters, hiatus, and complex patterns:"
10.times do |i|
  word = complex_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\n## Simple Elvish Names (2-3 syllables, Budget: 5)"
puts "Melodic names perfect for characters:"
8.times do |i|
  syllables = Random.rand(2..3)
  word = simple_generator.generate(syllables)
  capitalized_name = word.capitalize
  puts "#{i + 1}. #{capitalized_name}"
end

puts "\n## Vowel-initial Simple Names (Budget: 5)"
puts "Elegant flowing names starting with vowels:"
8.times do |i|
  syllables = Random.rand(2..3)
  word = simple_generator.generate(syllables, :vowel)
  capitalized_name = word.capitalize
  puts "#{i + 1}. #{capitalized_name}"
end

puts "\n## Complexity Budget System"
puts "• Budget 5: Simple, melodic words with vowel harmony"
puts "• Budget 8: Moderate complexity with occasional clusters" 
puts "• Budget 12: Complex words with full cluster and hiatus patterns"
puts "• Complexity costs: Clusters (3pts), Hiatus (2pts escalating), Complex codas (2pts)"
puts "• Hiatus escalation: 1st=2pts, 2nd=4pts, 3rd=8pts (prevents 'riemaotse' type words)"
puts "• When budget exhausted: Switches to simple CV patterns with vowel reuse"

puts "\n## Word Analysis Example"
puts "Analyzing target Elvish words to reverse-engineer patterns:"

# Example target words that we want to match
target_words = <<-WORDS.split("\n")
andrasy
nazagon
thadrae
raelma
thaesko
thomaze
zanyare
kidra
nadar
kana
vy
nyel
ny
ne
zaelon
darim
dakrion
kyrio
loron
lorvie
kem
ritzagra
gorom
aggonza
gorath
drayagra
jy
jyne
tiry
kyre
vos
kirith
ora
varanya
aggonya
aggorim
rimlare
rimakros
glys
lys
glysaro
kelin
kelinor
nadrena
agra
nadra
delara
ziskor
janye
jynyae
WORDS

# Analyze the target words
analyzer = WordMage::Analyzer.new(WordMage::RomanizationMap.new(romanization))
analysis = analyzer.analyze(target_words)

puts "\n### Individual Word Analysis"
word_analyzer = WordMage::WordAnalyzer.new(WordMage::RomanizationMap.new(romanization))
target_words.each do |word|
  word_analysis = word_analyzer.analyze(word)
  puts "#{word}: #{word_analysis.summary}"
end

puts "\n### Aggregate Analysis"
puts analysis.summary

puts "\n### Vowel Harmony Analysis"
puts "Detected vowel transitions:"
analysis.vowel_transitions.each do |from_vowel, transitions|
  puts "  #{romanization[from_vowel]} → "
  transitions.each do |to_vowel, frequency|
    percentage = (frequency * 100).round(1)
    puts "    #{romanization[to_vowel]}: #{percentage}%"
  end
end

puts "Vowel harmony strength: #{analysis.vowel_harmony_strength}"
puts "Transition diversity: #{analysis.vowel_transition_diversity.round(2)}"

puts "\n### Creating Generator from Analysis (with automatic vowel harmony)"
analyzed_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_romanization(romanization)
  .with_analysis_of_words(target_words)  # Automatically includes vowel harmony!
  .with_hiatus_escalation(2.0_f32)
  .with_vowel_harmony_strength(0.7_f32)  # Adjust harmony strength
  .random_mode
  .build

puts "\n### Words Generated from Analysis (should match target style)"
10.times do |i|
  word = analyzed_generator.generate
  puts "#{i + 1}. #{word}"
end

puts "\n### Vowel Harmony API Flexibility"

puts "\n## 1. Without vowel harmony:"
no_harmony_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "g", "k", "l", "m", "n", "r", "s", "t", "θ"], ["ɑ", "ɛ", "ɔ", "i", "u", "y"])
  .with_romanization(romanization)
  .with_analysis_of_words(target_words, vowel_harmony: false)  # Disable harmony
  .random_mode
  .build

5.times { |i| puts "#{i + 1}. #{no_harmony_gen.generate}" }

puts "\n## 2. With weak vowel harmony:"
weak_harmony_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "g", "k", "l", "m", "n", "r", "s", "t", "θ"], ["ɑ", "ɛ", "ɔ", "i", "u", "y"])
  .with_romanization(romanization)
  .with_analysis_of_words(target_words)  # Auto harmony
  .with_vowel_harmony_strength(0.3_f32)  # Make it weak
  .random_mode
  .build

5.times { |i| puts "#{i + 1}. #{weak_harmony_gen.generate}" }

puts "\n## 3. With strong vowel harmony:"
strong_harmony_gen = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "g", "k", "l", "m", "n", "r", "s", "t", "θ"], ["ɑ", "ɛ", "ɔ", "i", "u", "y"])
  .with_romanization(romanization)
  .with_analysis_of_words(target_words)  # Auto harmony  
  .with_vowel_harmony_strength(0.9_f32)  # Make it strong
  .random_mode
  .build

5.times { |i| puts "#{i + 1}. #{strong_harmony_gen.generate}" }

puts "\n### Saving Analysis to JSON"
json_data = analysis.to_json
puts "Analysis saved (#{json_data.size} characters)"
puts "Phoneme diversity: #{analysis.phoneme_diversity.round(2)}"
puts "Structural complexity: #{analysis.structural_complexity.round(2)}"
puts "Complexity preference: #{analysis.complexity_preference}"
puts "\nVowel Harmony Features:"
puts "• Automatic detection from with_analysis_of_words()"
puts "• Toggle: .with_vowel_harmony(false) or .with_vowel_harmony(true)"
puts "• Adjust strength: .with_vowel_harmony_strength(0.0-1.0)"
puts "• Manual rules: .with_vowel_harmony(custom_harmony_object)"