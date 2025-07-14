require "./src/wordmage"

# Reproduce the exact elvish setup to find the "rny" bug
onset_clusters = ["ml", "gl", "tr", "pr", "kr", "gr", "dr", "zr", "sp", "θr"]
coda_clusters = ["nd"]

cluster_template = WordMage::SyllableTemplate.new("CCV", 
  allowed_clusters: onset_clusters,
  hiatus_probability: 0.2_f32
)

coda_cluster_template = WordMage::SyllableTemplate.new("CVCC", 
  allowed_coda_clusters: coda_clusters,
  hiatus_probability: 0.1_f32
)

regular_template = WordMage::SyllableTemplate.new("CV", 
  hiatus_probability: 0.3_f32
)

complex_template = WordMage::SyllableTemplate.new("CVC", 
  hiatus_probability: 0.1_f32
)

ae_hiatus_template = WordMage::SyllableTemplate.new("V", hiatus_probability: 0.6_f32)

puts "=== Testing Individual Templates ==="

phoneme_set = WordMage::PhonemeSet.new(
  Set{"b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"}, 
  Set{"i", "u", "y", "ɑ", "ɔ", "ɛ"}
)

puts "\nCluster template (CCV):"
5.times do |i|
  syllable = cluster_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end

puts "\nCoda cluster template (CVCC):"
5.times do |i|
  syllable = coda_cluster_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end

puts "\nComplex template (CVC):"
5.times do |i|
  syllable = complex_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end