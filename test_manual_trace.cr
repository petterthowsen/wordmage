require "./src/wordmage"

# Create a generator but trace through the generation manually
phoneme_set = WordMage::PhonemeSet.new(["t", "n", "k"], ["a", "e"])
syllable_template1 = WordMage::SyllableTemplate.new("CV")
syllable_template2 = WordMage::SyllableTemplate.new("CVC")
syllable_count_spec = WordMage::SyllableCountSpec.exact(2)

word_spec = WordMage::WordSpec.new(
  syllable_count: syllable_count_spec,
  syllable_templates: [syllable_template1, syllable_template2]
)

romanizer = WordMage::RomanizationMap.new({
  "t" => "t", "n" => "n", "k" => "k", "a" => "a", "e" => "e"
})

# Create generator with gemination enabled
generator = WordMage::Generator.new(
  phoneme_set: phoneme_set,
  word_spec: word_spec,
  romanizer: romanizer,
  mode: WordMage::GenerationMode::Random,
  gemination_probability: 1.0_f32
)

# Let's manually trace through what should happen
puts "Manually tracing word generation:"
puts "=" * 50

# Simulate generating 2 CV syllables
syllable1 = ["t", "a"]  # CV
syllable2 = ["n", "a"]  # CV

syllables = [syllable1, syllable2]
phonemes = ["t", "a", "n", "a"]
puts "Initial syllables: #{syllables.inspect}"
puts "Flattened phonemes: #{phonemes.inspect}"

# Now manually check what can be geminated
puts "\nChecking which positions can be geminated:"
puts "- Position 0: 't' - at start, CAN'T geminate"
puts "- Position 1: 'a' - is vowel, CAN'T geminate"  
puts "- Position 2: 'n' - prev is 'a' (vowel), next is 'a' (not 'n'), CAN geminate!"
puts "- Position 3: 'a' - is vowel, CAN'T geminate"

puts "\nSo we should get a geminated word with 'nn' in it"

puts "\n" + "=" * 50
puts "Testing with actual generator:"

20.times do
  word = generator.generate
  puts word
end
