require "./src/wordmage"

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
kemye
ritzagra
gorom
aggonza
gorath
drayagra
ekir
drayeki
drakar
jy
jyne
tiry
kyre
nys
nysel
vos
kirith
ora
varanya
aggonya
aggon
aggorim
thaggor
naggar
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
thoro
WORDS

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

# Simplified clusters for more elegant words (using romanized forms)
onset_clusters = ["tr", "gr", "thr", "dr", "pr", "br", "skr", "kr"]  # Keep only the most flowing clusters
coda_clusters = ["n", "s", "r", "ml", "rv", "vl", "lv", "rs", "rz", "sl", "fl", "fr", "sk", "zk", "rn", "nt"]  # Simple codas instead of complex clusters

# Simplified syllable templates for more elegant words
cluster_template = WordMage::SyllableTemplate.new("CCV", 
  allowed_clusters: onset_clusters,
  hiatus_probability: 0.1_f32
)

# Simple coda template - single consonant endings
coda_template = WordMage::SyllableTemplate.new("CVC", 
  allowed_coda_clusters: coda_clusters,
  hiatus_probability: 0.1_f32
)

# Main CV template - most common pattern
regular_template = WordMage::SyllableTemplate.new("CV", 
  hiatus_probability: 0.1_f32
)

# Vowel template for elegant transitions
vowel_template = WordMage::SyllableTemplate.new("V",
  hiatus_probability: 0.1_f32
)

# Nasal template for words ending in nasals (common in Elvish)
nasal_template = WordMage::SyllableTemplate.new("CVN", 
  hiatus_probability: 0.1_f32,
  gemination_probability: 0,
)

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
puts "Gemination patterns: #{analysis.gemination_patterns.to_pretty_json}"
puts "Vowel lengthening patterns: #{analysis.vowel_lengthening_patterns.to_pretty_json}"

puts "\n### Creating Generator from Analysis (with explicit templates)"

# Define explicit templates with user-defined clusters
explicit_templates = [
  regular_template,   # CV patterns - most common
  vowel_template,     # V patterns for flow
  cluster_template,   # CCV with flowing onset clusters: ["tr", "gr", "thr", "dr"]
  coda_template,      # CVC with simple codas: ["n", "s", "r"]
  nasal_template      # CVN with nasal endings: ["m", "n", "ny"]
]

# Analyze using explicit templates instead of auto-generated ones
romanization_map = WordMage::RomanizationMap.new(romanization)
explicit_analyzer = WordMage::Analyzer.new(romanization_map)
explicit_analysis = explicit_analyzer
  .with_templates(explicit_templates)
  .analyze(target_words, true, 0.3_f32)

puts "\n### Explicit Template Analysis Results"
puts "Provided templates: #{explicit_analysis.provided_templates.not_nil!.map(&.pattern).join(", ")}"
puts "Recommended hiatus probability: #{explicit_analysis.recommended_hiatus_probability.round(3)}"
puts "Template-based analysis preserves user-defined clusters while detecting patterns"

# Add nasals as a custom group for patterns like CVN, NVC
analyzed_generator = WordMage::GeneratorBuilder.create
  .with_phonemes({
    'C' => ["b", "d", "f", "g", "k", "l", "p", "r", "s", "t", "v", "z", "ʒ", "θ"],
    'V' => ["i", "u", "y", "ɑ", "ɔ", "ɛ"],
    'N' => ["m", "n", "ɲ"]
  })
  .with_romanization(romanization)
  .with_syllable_templates(explicit_templates)  # Use the explicit templates with cluster constraints
  .with_analysis(explicit_analysis, analysis_weight_factor: 100.0_f32)
  .with_hiatus_escalation(10.0_f32)
  .with_vowel_harmony_strength(1.0_f32)
  .with_gemination_probability(0.1_f32)
  .with_vowel_lengthening_probability(0.1_f32)

  .with_complexity_budget(6)

  .with_cluster_cost(4)           # Make clusters more expensive
  .with_hiatus_cost(2)            # Make hiatus cheaper
  .with_gemination_cost(2)        # Make gemination cheaper
  .with_complex_coda_cost(4)      # Make complex codas more expensive
  .with_vowel_lengthening_cost(3) # Make vowel lengthening very cheap

  .random_mode
  .build

puts "\n### Words Generated from Analysis (should match target style)"
20.times do |i|
  word = analyzed_generator.generate
  puts "#{i + 1}. #{word}"
end