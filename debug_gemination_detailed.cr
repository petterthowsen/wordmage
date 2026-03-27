require "./src/wordmage"

# More detailed debugging - trace the generation process
module WordMage
  class Generator
    # Override generate_random to add debugging
    alias_method :original_generate_random, :generate_random
    
    def generate_random_debug : String
      starting_type = @word_spec.starting_type || :any
      original_syllable_count = @word_spec.syllable_count.random_count

      attempt = 0
      max_attempts = 100
      
      while attempt < max_attempts
        attempt += 1
        
        syllables = [] of Array(String)
        used_vowels = Set(String).new
        vowel_sequence = [] of String
        
        original_syllable_count.times do |syllable_index|
          position = case syllable_index
                    when 0
                      :initial
                    when original_syllable_count - 1
                      :final
                    else
                      :medial
                    end
          
          template = @syllable_templates.not_nil!.sample
          syllable = generate_syllable(template, position)
          syllables << syllable
        end
        
        phonemes = syllables.flatten
        puts "Before gemination (phonemes): #{phonemes.inspect}"
        puts "Gemination probability: #{@gemination_probability}"
        puts "Has gemination method enabled: #{@gemination_probability > 0.0}"

        # Apply gemination if enabled
        if @gemination_probability > 0.0 || syllables.any? { |s| 
          template = get_template_for_syllable(s)
          template && template.gemination_probability > 0.0
        }
          phonemes = apply_gemination_with_templates(phonemes, syllables)
          puts "After gemination (phonemes): #{phonemes.inspect}"
        end

        # Apply vowel lengthening if enabled
        if @vowel_lengthening_probability > 0.0 || syllables.any? { |s| 
          template = get_template_for_syllable(s)
          template && template.vowel_lengthening_probability > 0.0
        }
          phonemes = apply_vowel_lengthening_with_templates(phonemes, syllables)
          puts "After vowel lengthening (phonemes): #{phonemes.inspect}"
        end

        romanized_word = @romanizer.romanize(phonemes)
        puts "Romanized: #{romanized_word}"
        
        # Check vowel gemination
        has_vowel_gem = has_vowel_gemination?(phonemes)
        puts "Has vowel gemination: #{has_vowel_gem}"
        
        # Check validation
        syllable_count_valid = true
        if @word_spec.starts_with || @word_spec.ends_with
          actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
          syllable_count_valid = actual_syllable_count >= @word_spec.syllable_count.min && actual_syllable_count <= @word_spec.syllable_count.max
        else
          actual_syllable_count = WordAnalyzer.new(@romanizer).analyze(romanized_word).syllable_count
          syllable_count_valid = actual_syllable_count == original_syllable_count
        end
        
        word_valid = @word_spec.validate_word(phonemes, @romanizer)
        puts "Word valid: #{word_valid}"
        puts "Syllable count valid: #{syllable_count_valid}"
        
        puts "--\n"
        
        if attempt >= 3
          puts "Stopping after 3 attempts for debugging"
          break
        end

        if word_valid && matches_starting_type_override?(phonemes, starting_type) && !has_syllable_boundary_gemination?(syllables) && !has_excessive_vowel_sequences?(phonemes) && !has_vowel_gemination?(phonemes) && syllable_count_valid
          if @mode == GenerationMode::Sequential
            return romanized_word
          elsif !check_constraints(romanized_word)
            return romanized_word if check_constraints(romanized_word)
          end
        end
      end

      raise "No valid word generated after #{max_attempts} attempts"
    end
  end
end

# Test with debugging
generator = WordMage::GeneratorBuilder.create
  .with_phonemes(["t", "n"], ["a", "e"])
  .with_syllable_patterns(["CV"])
  .with_syllable_count(WordMage::SyllableCountSpec.exact(2))
  .with_gemination_probability(1.0)
  .build

puts "Attempting to generate with gemination..."
begin
  word = generator.generate_random_debug
  puts "Generated word: #{word}"
rescue ex
  puts "Error: #{ex.message}"
end
