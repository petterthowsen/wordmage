require "./src/wordmage"

# Minimal test to reproduce the "rny" issue
phoneme_set = WordMage::PhonemeSet.new(
  Set{"r", "n", "y", "f", "t", "h", "d"}, 
  Set{"u", "a", "e", "i"}
)

# Test different templates to see which ones create illegal sequences
puts "=== Testing Templates ==="

# Test CVC (should never have adjacent consonants)
cvc_template = WordMage::SyllableTemplate.new("CVC")
puts "\nCVC template:"
10.times do |i|
  syllable = cvc_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end

# Test CVCC with coda clusters
cvcc_template = WordMage::SyllableTemplate.new("CVCC", allowed_coda_clusters: ["nd"])
puts "\nCVCC template (nd coda only):"
10.times do |i|
  syllable = cvcc_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end

# Test complex template like your elvish one
complex_template = WordMage::SyllableTemplate.new("CVC", hiatus_probability: 0.1_f32)
puts "\nCVC with hiatus:"
10.times do |i|
  syllable = complex_template.generate(phoneme_set, :initial)
  puts "#{i+1}. #{syllable.join} (#{syllable.inspect})"
end