module WordMage
  # Defines syllable structure patterns with constraints and hiatus generation.
  #
  # SyllableTemplate specifies how syllables should be constructed using pattern
  # strings like "CV" (consonant-vowel), "CVC" (consonant-vowel-consonant), etc.
  # Supports hiatus (vowel sequences) and validation constraints.
  #
  # ## Pattern Symbols
  # - `C`: Consonant
  # - `V`: Vowel (may become VV with hiatus)
  #
  # ## Example
  # ```crystal
  # template = SyllableTemplate.new("CCV", ["rr"], hiatus_probability: 0.3_f32)
  # syllable = template.generate(phoneme_set, :initial)  # ["p", "r", "a", "e"]
  # ```
  class SyllableTemplate
    property pattern : String
    property constraints : Array(String)
    property hiatus_probability : Float32
    property position_weights : Hash(Symbol, Float32)
    property allowed_clusters : Array(String)?
    property allowed_coda_clusters : Array(String)?

    # Creates a new syllable template.
    #
    # ## Parameters
    # - `pattern`: Pattern string (e.g., "CV", "CVC", "CCV", "CVCC")
    # - `constraints`: Regex patterns that syllables must NOT match
    # - `hiatus_probability`: Chance (0.0-1.0) that V becomes VV
    # - `position_weights`: Weights for using this template at different positions
    # - `allowed_clusters`: Specific onset clusters allowed for CC patterns (optional)
    # - `allowed_coda_clusters`: Specific coda clusters allowed for CC at end (optional)
    def initialize(@pattern : String, @constraints : Array(String) = [] of String, @hiatus_probability : Float32 = 0.0_f32, @position_weights : Hash(Symbol, Float32) = Hash(Symbol, Float32).new, @allowed_clusters : Array(String)? = nil, @allowed_coda_clusters : Array(String)? = nil)
    end

    # Generates a syllable using this template.
    #
    # ## Parameters
    # - `phonemes`: PhonemeSet to sample from
    # - `position`: Syllable position (`:initial`, `:medial`, `:final`)
    #
    # ## Returns
    # Array of phoneme strings forming the syllable
    #
    # ## Note
    # Automatically retries if constraints are violated
    def generate(phonemes : PhonemeSet, position : Symbol) : Array(String)
      # Check if pattern has multiple consonants that would be adjacent
      if has_adjacent_consonants?
        # Multiple consonants patterns require explicit cluster definitions
        if @pattern.starts_with?("CC") || @pattern.ends_with?("CC")
          return generate_with_clusters(phonemes, position)
        else
          # Fallback to simpler pattern if no clusters defined
          return generate_fallback(phonemes, position)
        end
      end

      # Regular generation for simple patterns (C and V are never adjacent)
      syllable = [] of String

      @pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << phonemes.sample_phoneme(:consonant, position)
        when 'V'
          if allows_hiatus? && Random.rand < @hiatus_probability
            first_vowel = phonemes.sample_phoneme(:vowel, position)
            syllable << first_vowel
            # Generate a different vowel for hiatus
            second_vowel = generate_different_vowel(phonemes, first_vowel, position)
            syllable << second_vowel
          else
            syllable << phonemes.sample_phoneme(:vowel, position)
          end
        end
      end

      # Retry if constraints violated or has illegal sequences
      if validate(syllable) && !has_illegal_adjacent_consonants?(syllable)
        syllable
      else
        generate(phonemes, position)
      end
    end

    # Generates syllable using allowed clusters
    private def generate_with_clusters(phonemes : PhonemeSet, position : Symbol) : Array(String)
      available_consonants = phonemes.get_consonants(position).to_set
      syllable = [] of String
      
      # Handle onset consonants first
      if @pattern.starts_with?("CC")
        # Onset cluster required
        if onset_clusters = @allowed_clusters
          valid_onset_clusters = onset_clusters.select do |cluster|
            cluster.chars.all? { |char| available_consonants.includes?(char.to_s) }
          end
          
          if valid_onset_clusters.empty?
            return generate_fallback(phonemes, position)
          end
          
          # Add onset cluster
          chosen_cluster = valid_onset_clusters.sample
          syllable.concat(chosen_cluster.chars.map(&.to_s))
        else
          # Generate automatic clusters from available consonants
          consonants_array = available_consonants.to_a
          if consonants_array.size >= 2
            # Generate two different consonants
            first_consonant = consonants_array.sample
            remaining_consonants = consonants_array.reject { |c| c == first_consonant }
            second_consonant = remaining_consonants.empty? ? consonants_array.sample : remaining_consonants.sample
            syllable << first_consonant
            syllable << second_consonant
          else
            return generate_fallback(phonemes, position)
          end
        end
      elsif @pattern.starts_with?("C")
        # Single onset consonant
        syllable << phonemes.sample_phoneme(:consonant, position)
      end

      # Add vowels
      vowel_count = @pattern.count('V')
      vowel_count.times do
        if allows_hiatus? && Random.rand < @hiatus_probability
          first_vowel = phonemes.sample_phoneme(:vowel, position)
          syllable << first_vowel
          second_vowel = generate_different_vowel(phonemes, first_vowel, position)
          syllable << second_vowel
        else
          syllable << phonemes.sample_phoneme(:vowel, position)
        end
      end

      # Handle coda consonants
      if @pattern.ends_with?("CC")
        # Coda cluster required
        if coda_clusters = @allowed_coda_clusters
          valid_coda_clusters = coda_clusters.select do |cluster|
            cluster.chars.all? { |char| available_consonants.includes?(char.to_s) }
          end
          
          if !valid_coda_clusters.empty?
            chosen_coda_cluster = valid_coda_clusters.sample
            syllable.concat(chosen_coda_cluster.chars.map(&.to_s))
          else
            # No valid coda clusters available - fall back
            return generate_fallback(phonemes, position)
          end
        else
          # Generate automatic coda clusters from available consonants
          consonants_array = available_consonants.to_a
          if consonants_array.size >= 2
            # Generate two different consonants
            first_consonant = consonants_array.sample
            remaining_consonants = consonants_array.reject { |c| c == first_consonant }
            second_consonant = remaining_consonants.empty? ? consonants_array.sample : remaining_consonants.sample
            syllable << first_consonant
            syllable << second_consonant
          else
            return generate_fallback(phonemes, position)
          end
        end
      elsif @pattern.ends_with?("C") && !@pattern.starts_with?("C")
        # Single coda consonant (for patterns like VC)
        syllable << phonemes.sample_phoneme(:consonant, position)
      elsif @pattern.count('C') > syllable.count { |p| !phonemes.is_vowel?(p) }
        # Still missing consonants - something went wrong, fall back
        return generate_fallback(phonemes, position)
      end

      # Retry if constraints violated
      if validate(syllable)
        syllable
      else
        generate_with_clusters(phonemes, position)
      end
    end

    # Fallback to simpler pattern when clusters don't work
    private def generate_fallback(phonemes : PhonemeSet, position : Symbol) : Array(String)
      # Convert CCV -> CV, CCCV -> CV, etc.
      simplified_pattern = "C" + @pattern.gsub(/C+/, "C").gsub(/C/, "")
      
      syllable = [] of String
      simplified_pattern.each_char do |symbol|
        case symbol
        when 'C'
          syllable << phonemes.sample_phoneme(:consonant, position)
        when 'V'
          syllable << phonemes.sample_phoneme(:vowel, position)
        end
      end
      
      syllable
    end

    # Checks if this template can generate hiatus (vowel sequences).
    #
    # ## Returns
    # `true` if hiatus_probability > 0, `false` otherwise
    def allows_hiatus? : Bool
      @hiatus_probability > 0.0_f32
    end

    # Validates a syllable against constraints.
    #
    # ## Parameters
    # - `syllable`: Array of phonemes to validate
    #
    # ## Returns
    # `true` if syllable passes all constraints, `false` otherwise
    def validate(syllable : Array(String)) : Bool
      sequence = syllable.join
      @constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
    end

    # Generates a vowel different from the given vowel for hiatus.
    #
    # ## Parameters
    # - `phonemes`: PhonemeSet to sample from
    # - `exclude_vowel`: The vowel to avoid (to prevent gemination)
    # - `position`: Syllable position
    #
    # ## Returns
    # A different vowel, or the same vowel if no alternatives exist
    private def generate_different_vowel(phonemes : PhonemeSet, exclude_vowel : String, position : Symbol) : String
      available_vowels = phonemes.get_vowels(position).reject { |v| v == exclude_vowel }
      
      if available_vowels.empty?
        # Fallback to any vowel if no alternatives (rare case)
        phonemes.sample_phoneme(:vowel, position)
      else
        # Use weighted sampling if weights exist
        if phonemes.weights.empty?
          available_vowels.sample
        else
          weighted_sample_vowels(available_vowels, phonemes)
        end
      end
    end

    # Weighted sampling for vowels excluding specific vowel
    private def weighted_sample_vowels(candidates : Array(String), phonemes : PhonemeSet) : String
      weighted_candidates = candidates.select { |c| phonemes.weights.has_key?(c) }
      
      if weighted_candidates.empty?
        return candidates.sample
      end

      total_weight = weighted_candidates.sum { |c| phonemes.weights[c] }
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      weighted_candidates.each do |candidate|
        current_weight += phonemes.weights[candidate]
        return candidate if current_weight >= target
      end

      weighted_candidates.first
    end

    # Checks if this pattern would create adjacent consonants
    private def has_adjacent_consonants? : Bool
      # Look for CC sequences in the pattern
      @pattern.includes?("CC") || 
      # Or patterns like CVCVC where middle Cs could be problematic
      (@pattern.count('C') > 1 && has_potential_consonant_adjacency?)
    end

    # Checks if pattern could create consonant adjacency issues
    private def has_potential_consonant_adjacency? : Bool
      # For patterns like CVC, consonants are separated by vowels so no adjacency
      # For patterns like CCVC, CVCC, or longer patterns, check for adjacent Cs
      prev_was_c = false
      @pattern.each_char do |char|
        if char == 'C'
          return true if prev_was_c  # Found CC
          prev_was_c = true
        else
          prev_was_c = false
        end
      end
      false
    end

    # Checks if syllable has illegal adjacent consonants (not in defined clusters)
    private def has_illegal_adjacent_consonants?(syllable : Array(String)) : Bool
      return false if syllable.size < 2
      
      # Find all adjacent consonant pairs
      (0...syllable.size-1).each do |i|
        current = syllable[i]
        next_phoneme = syllable[i+1]
        
        # Skip if not both consonants
        next if is_vowel?(current) || is_vowel?(next_phoneme)
        
        # We have adjacent consonants - check if they're in allowed clusters
        cluster = current + next_phoneme
        
        # Determine if this is onset or coda position
        is_onset = i == 0
        is_coda = i+1 == syllable.size-1
        
        if is_onset && @allowed_clusters
          return true unless @allowed_clusters.not_nil!.includes?(cluster)
        elsif is_coda && @allowed_coda_clusters
          return true unless @allowed_coda_clusters.not_nil!.includes?(cluster)
        else
          # Adjacent consonants not in defined positions - illegal
          return true
        end
      end
      
      false
    end

    # Helper method to check if phoneme is vowel
    private def is_vowel?(phoneme : String) : Bool
      %w[i u y ɑ ɔ ɛ a e o].includes?(phoneme)
    end
  end
end