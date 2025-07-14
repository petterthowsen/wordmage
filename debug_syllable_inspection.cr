require "./src/wordmage"

# Test with exact elvish setup and inspect syllables
romanization = {
  "b" => "b", "d" => "d", "f" => "f", "g" => "g", "k" => "k", "l" => "l", "m" => "m", 
  "n" => "n", "p" => "p", "r" => "r", "s" => "s", "t" => "t", 
  "v" => "v", "z" => "z",
  "ɲ" => "ny", "ʒ" => "j", "θ" => "th",
  "i" => "i", "u" => "u", "y" => "y", 
  "ɑ" => "a", "ɔ" => "o", "ɛ" => "e"
}

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

elvish_generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z", "ɲ", "ʒ", "θ"], 
                 ["i", "u", "y", "ɑ", "ɔ", "ɛ"])
  .with_syllable_templates([
    regular_template,       
    complex_template,       
    cluster_template,       
    coda_cluster_template,  
    ae_hiatus_template      
  ])
  .with_syllable_count(WordMage::SyllableCountSpec.weighted({
    2 => 2.0_f32,
    3 => 3.0_f32,
    4 => 2.0_f32,
    5 => 1.0_f32
  }))
  .with_romanization(romanization)
  .random_mode
  .build

puts "=== Looking for problematic sequences ==="

# Generate many words and look for illegal sequences
100.times do |i|
  word = elvish_generator.generate
  
  # Check for the specific problematic sequences
  if word.includes?("rny") || word.includes?("dz") || word.includes?("ndpr")
    puts "FOUND PROBLEM: #{word}"
    
    # Let's manually break it down to understand the syllable structure
    if word.includes?("rny")
      puts "  -> Contains 'rny' sequence"
    end
    if word.includes?("dz")
      puts "  -> Contains 'dz' sequence"  
    end
    if word.includes?("ndpr")
      puts "  -> Contains 'ndpr' sequence"
    end
  end
end

puts "Done scanning 100 words."