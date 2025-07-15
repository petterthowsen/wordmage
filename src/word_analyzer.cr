require "./word_analysis"
require "./romanization_map"

module WordMage
  # Analyzes individual words to extract phonological patterns and structure.
  #
  # WordAnalyzer takes romanized words and uses a romanization map to
  # reverse-engineer the phonemic structure, detecting syllables, clusters,
  # hiatus sequences, and calculating complexity scores.
  #
  # ## Example
  # ```crystal
  # romanization = RomanizationMap.new({
  #   "th" => "θ", "dr" => "dr", "a" => "ɑ", "e" => "ɛ", "o" => "ɔ"
  # })
  # analyzer = WordAnalyzer.new(romanization)
  # analysis = analyzer.analyze("thadrae")
  # puts analysis.syllable_count  # 2
  # puts analysis.clusters        # ["θ", "dr"]
  # ```
  class WordAnalyzer
    @reverse_romanization : Hash(String, String)
    @vowel_phonemes : Set(String)
    @consonant_phonemes : Set(String)

    # Creates a new WordAnalyzer.
    #
    # ## Parameters
    # - `romanization_map`: RomanizationMap for converting romanized text to phonemes
    def initialize(@romanization_map : RomanizationMap)
      @reverse_romanization = create_reverse_mapping(@romanization_map.mappings)
      @vowel_phonemes = Set(String).new
      @consonant_phonemes = Set(String).new
      classify_phonemes
    end

    # Analyzes a romanized word to extract phonological structure.
    #
    # ## Parameters
    # - `word`: The romanized word to analyze
    #
    # ## Returns
    # WordAnalysis containing detailed structural information
    #
    # ## Example
    # ```crystal
    # analysis = analyzer.analyze("nazagon")
    # puts analysis.syllable_count     # 3
    # puts analysis.consonant_count    # 4
    # puts analysis.vowel_count        # 3
    # ```
    def analyze(word : String) : WordAnalysis
      # Convert romanized word to phonemes
      phonemes = romanized_to_phonemes(word)
      
      # Analyze syllable structure
      syllables = detect_syllables(phonemes)
      syllable_patterns = syllables.map { |syllable| detect_syllable_pattern(syllable) }
      
      # Count phoneme types
      consonant_count = phonemes.count { |p| is_consonant?(p) }
      vowel_count = phonemes.count { |p| is_vowel?(p) }
      
      # Detect clusters and hiatus
      clusters = detect_clusters(phonemes)
      hiatus_sequences = detect_hiatus(phonemes)
      
      # Detect gemination and vowel lengthening
      gemination_sequences = detect_gemination(phonemes)
      vowel_lengthening_sequences = detect_vowel_lengthening(phonemes)
      
      # Calculate complexity score
      complexity_score = calculate_complexity(clusters, hiatus_sequences, syllable_patterns)
      
      # Analyze phoneme positions
      phoneme_positions = analyze_phoneme_positions(phonemes)
      
      WordAnalysis.new(
        syllable_count: syllables.size,
        consonant_count: consonant_count,
        vowel_count: vowel_count,
        hiatus_count: hiatus_sequences.size,
        cluster_count: clusters.size,
        complexity_score: complexity_score,
        phonemes: phonemes,
        syllable_patterns: syllable_patterns,
        clusters: clusters,
        hiatus_sequences: hiatus_sequences,
        phoneme_positions: phoneme_positions,
        gemination_sequences: gemination_sequences,
        vowel_lengthening_sequences: vowel_lengthening_sequences
      )
    end

    # Converts romanized text to phonemes using the reverse romanization map.
    #
    # ## Parameters
    # - `word`: Romanized word
    #
    # ## Returns
    # Array of phoneme strings
    private def romanized_to_phonemes(word : String) : Array(String)
      phonemes = [] of String
      i = 0
      
      while i < word.size
        # Try longest matches first
        found_match = false
        
        # Look for multi-character romanizations (e.g., "th" -> "θ")
        (2..4).reverse_each do |length|
          next if i + length > word.size
          
          substring = word[i, length]
          if phoneme = @reverse_romanization[substring]?
            phonemes << phoneme
            i += length
            found_match = true
            break
          end
        end
        
        # If no multi-character match, try single character
        unless found_match
          char = word[i].to_s
          phonemes << (@reverse_romanization[char]? || char)
          i += 1
        end
      end
      
      phonemes
    end

    # Detects syllable boundaries in phoneme array.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Array of syllables, where each syllable is an array of phonemes
    def detect_syllables(phonemes : Array(String)) : Array(Array(String))
      return [] of Array(String) if phonemes.empty?
      return [phonemes] if phonemes.size <= 2
      
      syllables = [] of Array(String)
      current_syllable = [] of String
      i = 0
      
      syllable_closed = false
      
      while i < phonemes.size
        current_syllable << phonemes[i]
        
        # Check for syllable boundary after this phoneme
        if i == phonemes.size - 1
          # End of word - close current syllable
          syllables << current_syllable
          syllable_closed = true
        elsif is_vowel?(phonemes[i])
          # After a vowel, check what comes next
          next_i = i + 1
          
          if next_i < phonemes.size
            next_phoneme = phonemes[next_i]
            
            if is_vowel?(next_phoneme)
              # Two vowels in a row - check context to decide if they should be split
              if phonemes[i] == next_phoneme
                # Same vowel repeated - likely vowel lengthening, keep in same syllable
                current_syllable << next_phoneme
                i = next_i
                
                # Check if there's more content after this vowel sequence
                if next_i + 1 < phonemes.size && is_consonant?(phonemes[next_i + 1])
                  # Create syllable boundary after vowel lengthening
                  syllables << current_syllable
                  current_syllable = [] of String
                end
              else
                # Different vowels - decide based on phonetic context
                # Check if there's a consonant after the second vowel
                if next_i + 1 < phonemes.size && is_consonant?(phonemes[next_i + 1])
                  # Pattern: C...V1 V2 C - split as C...V1 | V2 C (like "ta-e-ron" or "spra-e-to")
                  syllables << current_syllable
                  current_syllable = [] of String
                else
                  # No consonant after second vowel - keep vowel sequences together
                  current_syllable << next_phoneme
                  i = next_i
                  
                  # Check if there's more content after this vowel sequence
                  if next_i + 1 < phonemes.size && is_consonant?(phonemes[next_i + 1])
                    # Create syllable boundary after the vowel sequence
                    syllables << current_syllable
                    current_syllable = [] of String
                  end
                end
              end
            elsif is_consonant?(next_phoneme)
              # V + C pattern - standard syllable boundary logic
              consonant_count = 0
              look_ahead = next_i
              
              # Count consecutive consonants
              while look_ahead < phonemes.size && is_consonant?(phonemes[look_ahead])
                consonant_count += 1
                look_ahead += 1
              end
              
              # If we have a vowel after the consonants, decide where to split
              if look_ahead < phonemes.size && is_vowel?(phonemes[look_ahead])
                if consonant_count == 1
                  # V + C + V pattern - boundary after vowel
                  syllables << current_syllable
                  current_syllable = [] of String
                elsif consonant_count >= 2
                  # V + CC... + V pattern - split consonants
                  # Take first consonant with current syllable
                  current_syllable << phonemes[next_i]
                  syllables << current_syllable
                  current_syllable = [] of String
                  i = next_i  # Skip the consonant we just added
                end
              end
            end
          end
        end
        
        i += 1
      end
      
      # Only add the current syllable if it wasn't already closed
      if !syllable_closed && !current_syllable.empty?
        syllables << current_syllable
      end
      
      # Ensure we don't have empty syllables
      syllables.reject(&.empty?)
    end

    # Detects the pattern of a syllable (CV, CVC, etc.).
    #
    # ## Parameters
    # - `syllable`: Array of phonemes in the syllable
    #
    # ## Returns
    # String representing the syllable pattern
    private def detect_syllable_pattern(syllable : Array(String)) : String
      pattern = ""
      
      syllable.each do |phoneme|
        if is_vowel?(phoneme)
          pattern += "V"
        else
          pattern += "C"
        end
      end
      
      pattern
    end

    # Detects consonant clusters in the phoneme array.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Array of consonant cluster strings
    private def detect_clusters(phonemes : Array(String)) : Array(String)
      clusters = [] of String
      i = 0
      
      while i < phonemes.size
        if is_consonant?(phonemes[i])
          cluster = phonemes[i]
          j = i + 1
          
          # Extend cluster while we have consonants
          while j < phonemes.size && is_consonant?(phonemes[j])
            cluster += phonemes[j]
            j += 1
          end
          
          # Only count as cluster if more than one consonant
          if cluster.size > 1
            clusters << cluster
          end
          
          i = j
        else
          i += 1
        end
      end
      
      clusters
    end

    # Detects hiatus sequences (adjacent vowels) in the phoneme array.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Array of hiatus sequence strings
    private def detect_hiatus(phonemes : Array(String)) : Array(String)
      hiatus = [] of String
      i = 0
      
      while i < phonemes.size
        if is_vowel?(phonemes[i])
          sequence = phonemes[i]
          j = i + 1
          
          # Extend sequence while we have vowels
          while j < phonemes.size && is_vowel?(phonemes[j])
            sequence += phonemes[j]
            j += 1
          end
          
          # Only count as hiatus if more than one vowel
          if sequence.size > 1
            hiatus << sequence
          end
          
          i = j
        else
          i += 1
        end
      end
      
      hiatus
    end

    # Calculates complexity score based on various factors.
    #
    # ## Parameters
    # - `clusters`: Array of consonant clusters
    # - `hiatus_sequences`: Array of hiatus sequences
    # - `syllable_patterns`: Array of syllable patterns
    #
    # ## Returns
    # Int32 complexity score
    private def calculate_complexity(clusters : Array(String), hiatus_sequences : Array(String), syllable_patterns : Array(String)) : Int32
      score = 0
      
      # Clusters add complexity
      clusters.each { |cluster| score += cluster.size * 2 }
      
      # Hiatus sequences add complexity
      hiatus_sequences.each { |hiatus| score += hiatus.size }
      
      # Complex syllable patterns add complexity
      syllable_patterns.each do |pattern|
        case pattern
        when "CV"
          score += 1
        when "CVC"
          score += 2
        when "CCV", "CVV"
          score += 3
        when "CCVC", "CVCC"
          score += 4
        else
          score += pattern.size
        end
      end
      
      score
    end

    # Analyzes the positions of phonemes in the word.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Hash mapping positions to arrays of phonemes
    private def analyze_phoneme_positions(phonemes : Array(String)) : Hash(Symbol, Array(String))
      positions = Hash(Symbol, Array(String)).new { |h, k| h[k] = [] of String }
      
      phonemes.each_with_index do |phoneme, i|
        position = case i
                   when 0 then :initial
                   when phonemes.size - 1 then :final
                   else :medial
                   end
        
        positions[position] << phoneme
      end
      
      positions
    end

    # Creates a reverse mapping from romanization to phonemes.
    #
    # ## Parameters
    # - `mappings`: Hash mapping phonemes to romanization
    #
    # ## Returns
    # Hash mapping romanization to phonemes
    private def create_reverse_mapping(mappings : Hash(String, String)) : Hash(String, String)
      reverse = Hash(String, String).new
      
      mappings.each do |phoneme, romanization|
        reverse[romanization] = phoneme
      end
      
      reverse
    end

    # Classifies phonemes into vowels and consonants based on known patterns.
    private def classify_phonemes
      # Common vowel phonemes
      vowels = ["a", "e", "i", "o", "u", "y", "ɑ", "ɛ", "ɪ", "ɔ", "ʊ", "ə", "æ", "ʌ", "ɒ"]
      
      @romanization_map.mappings.each do |phoneme, romanization|
        if vowels.includes?(phoneme) || vowels.includes?(romanization)
          @vowel_phonemes.add(phoneme)
        else
          @consonant_phonemes.add(phoneme)
        end
      end
    end

    # Checks if a phoneme is a vowel.
    #
    # ## Parameters
    # - `phoneme`: The phoneme to check
    #
    # ## Returns
    # `true` if the phoneme is a vowel, `false` otherwise
    private def is_vowel?(phoneme : String) : Bool
      @vowel_phonemes.includes?(phoneme) || 
      ["a", "e", "i", "o", "u", "y", "ɑ", "ɛ", "ɪ", "ɔ", "ʊ", "ə", "æ", "ʌ", "ɒ"].includes?(phoneme)
    end

    # Checks if a phoneme is a consonant.
    #
    # ## Parameters
    # - `phoneme`: The phoneme to check
    #
    # ## Returns
    # `true` if the phoneme is a consonant, `false` otherwise
    private def is_consonant?(phoneme : String) : Bool
      !is_vowel?(phoneme)
    end

    # Detects gemination sequences (doubled consonants) in the phoneme array.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Array of gemination sequence strings
    private def detect_gemination(phonemes : Array(String)) : Array(String)
      gemination = [] of String
      i = 0
      
      while i < phonemes.size - 1
        current = phonemes[i]
        next_phoneme = phonemes[i + 1]
        
        # Check for identical adjacent consonants
        if is_consonant?(current) && current == next_phoneme
          # Look ahead to see if there are more of the same consonant
          sequence = current + next_phoneme
          j = i + 2
          
          while j < phonemes.size && phonemes[j] == current
            sequence += phonemes[j]
            j += 1
          end
          
          gemination << sequence
          i = j  # Skip past the entire sequence
        else
          i += 1
        end
      end
      
      gemination
    end

    # Detects vowel lengthening sequences (doubled vowels) in the phoneme array.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes
    #
    # ## Returns
    # Array of vowel lengthening sequence strings
    private def detect_vowel_lengthening(phonemes : Array(String)) : Array(String)
      lengthening = [] of String
      i = 0
      
      while i < phonemes.size - 1
        current = phonemes[i]
        next_phoneme = phonemes[i + 1]
        
        # Check for identical adjacent vowels
        if is_vowel?(current) && current == next_phoneme
          # Look ahead to see if there are more of the same vowel
          sequence = current + next_phoneme
          j = i + 2
          
          while j < phonemes.size && phonemes[j] == current
            sequence += phonemes[j]
            j += 1
          end
          
          lengthening << sequence
          i = j  # Skip past the entire sequence
        else
          i += 1
        end
      end
      
      lengthening
    end
  end
end