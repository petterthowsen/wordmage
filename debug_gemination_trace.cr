require "./src/wordmage"

# Patch the generator to add debugging  
module WordMage
  class Generator
    alias_method :orig_apply_gemination, :apply_gemination_with_templates
    
    def apply_gemination_with_templates(phonemes : Array(String), syllables : Array(Array(String))) : Array(String)
      puts "[GEMINATION] Input: #{phonemes.inspect}"
      result = orig_apply_gemination(phonemes, syllables)
      puts "[GEMINATION] Output: #{result.inspect}"
      result
    end
  end
end

# Create a simple generator
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n"], ["a", "e"])
  .with_syllable_patterns(["CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .with_gemination_probability(1.0)
  .build

puts "Generating words with 100% gemination..."
puts "=" * 60

5.times do |i|
  word = generator.generate
  puts "\nGenerated word #{i + 1}: #{word}"
end
