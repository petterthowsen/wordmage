module WordMage
  # Specifies how many syllables a word should have.
  #
  # Supports three modes:
  # - **Exact**: Always generate exactly N syllables
  # - **Range**: Generate between min and max syllables (uniform distribution)
  # - **Weighted**: Generate syllables according to weighted probabilities
  #
  # ## Example
  # ```crystal
  # exact = SyllableCountSpec.exact(3)                    # Always 3 syllables
  # range = SyllableCountSpec.range(2, 4)                 # 2-4 syllables
  # weighted = SyllableCountSpec.weighted({2 => 1.0, 3 => 3.0, 4 => 1.0})  # Prefer 3
  # ```
  struct SyllableCountSpec
    enum Type
      Exact
      Range
      Weighted
    end

    getter type : Type
    getter min : Int32
    getter max : Int32
    getter weights : Hash(Int32, Float32)?

    def initialize(@type : Type, @min : Int32, @max : Int32, @weights : Hash(Int32, Float32)? = nil)
    end

    # Creates a spec for exactly N syllables.
    def self.exact(count : Int32)
      new(Type::Exact, count, count)
    end

    # Creates a spec for a range of syllables with uniform distribution.
    def self.range(min : Int32, max : Int32)
      new(Type::Range, min, max)
    end

    # Creates a spec for weighted syllable distribution.
    #
    # ## Parameters
    # - `weights`: Hash mapping syllable counts to their relative weights
    def self.weighted(weights : Hash(Int32, Float32))
      min_count = weights.keys.min
      max_count = weights.keys.max
      new(Type::Weighted, min_count, max_count, weights)
    end

    # Generates a syllable count according to this spec.
    #
    # ## Returns
    # Number of syllables for the word
    def generate_count : Int32
      case @type
      when .exact? then @min
      when .range? then Random.rand(@min..@max)
      when .weighted? then weighted_choice(@weights.not_nil!)
      else
        raise "Unknown syllable count type: #{@type}"
      end
    end

    private def weighted_choice(weights : Hash(Int32, Float32)) : Int32
      total_weight = weights.values.sum
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      weights.each do |count, weight|
        current_weight += weight
        return count if current_weight >= target
      end

      # Fallback
      weights.keys.first
    end
  end

  # Specifies requirements for word generation.
  #
  # WordSpec combines all the rules and constraints for generating words:
  # syllable count, starting phoneme type, available templates, and constraints.
  #
  # ## Example
  # ```crystal
  # syllable_count = SyllableCountSpec.range(2, 4)
  # templates = [SyllableTemplate.new("CV"), SyllableTemplate.new("CVC")]
  # spec = WordSpec.new(
  #   syllable_count: syllable_count,
  #   syllable_templates: templates,
  #   starting_type: :vowel,
  #   word_constraints: ["rr", "ss"]  # No double consonants
  # )
  # ```
  class WordSpec
    property syllable_count : SyllableCountSpec
    property starting_type : Symbol?
    property syllable_templates : Array(SyllableTemplate)
    property word_constraints : Array(String)
    property thematic_vowel : String?
    property starts_with : String?
    property ends_with : String?
    
    # Cost settings for template selection
    property template_cluster_cost_factor : Float32 = 1.0_f32
    property template_coda_cost_factor : Float32 = 1.0_f32

    # Creates a new WordSpec.
    #
    # ## Parameters
    # - `syllable_count`: How many syllables to generate
    # - `syllable_templates`: Available syllable patterns
    # - `starting_type`: Optional constraint on first phoneme (`:vowel` or `:consonant`)
    # - `word_constraints`: Regex patterns that words must NOT match
    # - `thematic_vowel`: Optional constraint forcing the last vowel to be this specific vowel
    # - `starts_with`: Optional constraint forcing words to start with this exact sequence
    # - `ends_with`: Optional constraint forcing words to end with this exact sequence
    # - `template_cluster_cost_factor`: Cost factor for templates with consonant clusters (default: 1.0)
    # - `template_coda_cost_factor`: Cost factor for templates with complex codas (default: 1.0)
    def initialize(@syllable_count : SyllableCountSpec, @syllable_templates : Array(SyllableTemplate), @starting_type : Symbol? = nil, @word_constraints : Array(String) = [] of String, @thematic_vowel : String? = nil, @starts_with : String? = nil, @ends_with : String? = nil, @template_cluster_cost_factor : Float32 = 1.0_f32, @template_coda_cost_factor : Float32 = 1.0_f32)
    end

    # Generates the number of syllables for a word.
    #
    # ## Returns
    # Number of syllables according to the syllable count spec
    def generate_syllable_count : Int32
      @syllable_count.generate_count
    end

    # Selects a syllable template for the given position.
    #
    # ## Parameters
    # - `position`: Syllable position (`:initial`, `:medial`, `:final`)
    # - `cluster_cost`: Optional cost for consonant clusters (default: 0)
    # - `coda_cost`: Optional cost for complex codas (default: 0)
    #
    # ## Returns
    # A syllable template, respecting probability, position weights, and costs
    def select_template(position : Symbol, cluster_cost : Float32 = 0.0_f32, coda_cost : Float32 = 0.0_f32) : SyllableTemplate
      # Filter templates that have position weights for this position
      position_weighted_templates = @syllable_templates.select { |t| t.position_weights.has_key?(position) }
      templates_to_use = position_weighted_templates.empty? ? @syllable_templates : position_weighted_templates
      
      # Apply cost-aware selection if costs are provided
      if cluster_cost > 0.0 || coda_cost > 0.0
        return cost_aware_template_selection(templates_to_use, position, cluster_cost, coda_cost)
      end
      
      # Otherwise use the original selection method
      if position_weighted_templates.empty?
        # No position weights - use template probability only
        weighted_sample_by_probability(@syllable_templates)
      else
        # Use combined weight: template probability * position weight
        total_weight = position_weighted_templates.sum { |t| t.probability * t.position_weights[position] }
        target = Random.rand * total_weight
        current_weight = 0.0_f32

        position_weighted_templates.each do |template|
          current_weight += template.probability * template.position_weights[position]
          return template if current_weight >= target
        end

        position_weighted_templates.first
      end
    end
    
    # Selects a syllable template taking into account cluster and coda costs
    #
    # ## Parameters
    # - `templates`: Array of templates to choose from
    # - `position`: Syllable position (`:initial`, `:medial`, `:final`)
    # - `cluster_cost`: Cost for consonant clusters
    # - `coda_cost`: Cost for complex codas
    #
    # ## Returns
    # A template selected with cost-aware weighting
    private def cost_aware_template_selection(templates : Array(SyllableTemplate), position : Symbol, cluster_cost : Float32, coda_cost : Float32) : SyllableTemplate
      # Calculate adjusted weights based on costs
      adjusted_weights = templates.map do |template|
        base_weight = position ? (template.probability * (template.position_weights[position]? || 1.0_f32)) : template.probability
        
        # Apply cluster costs if template allows clusters or contains CC in pattern
        cluster_penalty = 1.0_f32
        if template.allowed_clusters || template.pattern.includes?("CC")
          # The higher the cost, the lower the resulting weight
          cluster_penalty = Math.max(0.001_f32, 1.0_f32 / (1.0_f32 + cluster_cost * @template_cluster_cost_factor))
        end
        
        # Apply coda costs if template has complex codas
        coda_penalty = 1.0_f32
        if template.allowed_coda_clusters || template.pattern.ends_with?("CC")
          coda_penalty = Math.max(0.001_f32, 1.0_f32 / (1.0_f32 + coda_cost * @template_coda_cost_factor))
        end
        
        # Final weight is product of base weight and penalties
        {template, base_weight * cluster_penalty * coda_penalty}
      end
      
      # Weighted random selection using adjusted weights
      total_weight = adjusted_weights.sum { |_, weight| weight }
      return templates.sample if total_weight <= 0.0_f32 # Fallback if all weights are 0
      
      target = Random.rand * total_weight
      current_weight = 0.0_f32
      
      adjusted_weights.each do |template, weight|
        current_weight += weight
        return template if current_weight >= target
      end
      
      # Fallback
      templates.first
    end

    # Selects a template using weighted sampling based on probability only
    private def weighted_sample_by_probability(templates : Array(SyllableTemplate)) : SyllableTemplate
      total_weight = templates.sum(&.probability)
      target = Random.rand * total_weight
      current_weight = 0.0_f32

      templates.each do |template|
        current_weight += template.probability
        return template if current_weight >= target
      end

      templates.first
    end

    # Validates a word against constraints.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `romanizer`: Optional romanizer for thematic vowel validation and sequence constraints
    #
    # ## Returns
    # `true` if word passes all constraints, `false` otherwise
    def validate_word(phonemes : Array(String), romanizer : RomanizationMap? = nil) : Bool
      sequence = phonemes.join
      return false unless @word_constraints.none? { |pattern| sequence.matches?(Regex.new(pattern)) }
      
      # Check thematic vowel constraint
      if thematic = @thematic_vowel
        return false unless validate_thematic_vowel(phonemes, thematic, romanizer)
      end
      
      # Check starts_with constraint
      if prefix = @starts_with
        return false unless romanizer && validate_starts_with(phonemes, prefix, romanizer)
      end
      
      # Check ends_with constraint
      if suffix = @ends_with
        return false unless romanizer && validate_ends_with(phonemes, suffix, romanizer)
      end
      
      true
    end

    # Validates that the last vowel in the word matches the thematic vowel.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `thematic_vowel`: The required last vowel (in romanized form)
    # - `romanizer`: Romanizer to convert phonemes to text
    #
    # ## Returns
    # `true` if the last vowel matches the thematic vowel, `false` otherwise
    private def validate_thematic_vowel(phonemes : Array(String), thematic_vowel : String, romanizer : RomanizationMap?) : Bool
      return false unless romanizer
      
      # Convert to romanized text
      romanized_word = romanizer.romanize(phonemes)
      
      # Search backwards for the last vowel in romanized text
      # Use simple character-by-character approach since thematic vowel should be single character
      romanized_word.chars.reverse.each do |char|
        char_str = char.to_s
        if IPA::Utils.is_vowel?(char_str)
          return char_str == thematic_vowel
        end
      end
      
      # No vowels found - can't satisfy thematic vowel constraint
      false
    end

    # Validates that the word starts with the required sequence.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `prefix`: The required starting sequence (romanized)
    # - `romanizer`: RomanizationMap to convert romanization to phonemes
    #
    # ## Returns
    # `true` if the word starts with the required sequence, `false` otherwise
    private def validate_starts_with(phonemes : Array(String), prefix : String, romanizer : RomanizationMap) : Bool
      # Convert romanized prefix to phonemes using the same logic as get_required_prefix
      prefix_phonemes = convert_romanization_to_phonemes(prefix, romanizer)
      
      # Check if word starts with the required sequence
      return false if phonemes.size < prefix_phonemes.size
      
      (0...prefix_phonemes.size).each do |i|
        return false if phonemes[i] != prefix_phonemes[i]
      end
      
      true
    end

    # Gets the required starting phonemes for the starts_with constraint.
    #
    # ## Parameters
    # - `romanizer`: RomanizationMap to convert romanization to phonemes
    #
    # ## Returns
    # Array of phonemes that must start the word, or empty array if no constraint
    def get_required_prefix(romanizer : RomanizationMap) : Array(String)
      if prefix = @starts_with
        # Use the same logic as WordAnalyzer to convert romanization to phonemes
        convert_romanization_to_phonemes(prefix, romanizer)
      else
        [] of String
      end
    end

    # Validates that the word ends with the required sequence.
    #
    # ## Parameters
    # - `phonemes`: Array of phonemes forming the word
    # - `suffix`: The required ending sequence (romanized)
    # - `romanizer`: RomanizationMap to convert romanization to phonemes
    #
    # ## Returns
    # `true` if the word ends with the required sequence, `false` otherwise
    private def validate_ends_with(phonemes : Array(String), suffix : String, romanizer : RomanizationMap) : Bool
      # Convert romanized suffix to phonemes using the same logic as get_required_suffix
      suffix_phonemes = convert_romanization_to_phonemes(suffix, romanizer)
      
      # Check if word ends with the required sequence
      return false if phonemes.size < suffix_phonemes.size
      
      # Compare the end of the word with the suffix
      start_index = phonemes.size - suffix_phonemes.size
      (0...suffix_phonemes.size).each do |i|
        return false if phonemes[start_index + i] != suffix_phonemes[i]
      end
      
      true
    end

    # Gets the required ending phonemes for the ends_with constraint.
    #
    # ## Returns
    # Array of phonemes that must end the word, or empty array if no constraint
    def get_required_suffix(romanizer : RomanizationMap) : Array(String)
      if suffix = @ends_with
        # Use the same logic as WordAnalyzer to convert romanization to phonemes
        convert_romanization_to_phonemes(suffix, romanizer)
      else
        [] of String
      end
    end
    
    # Converts romanized text to phonemes using the romanization map.
    # This uses the same algorithm as WordAnalyzer.
    #
    # ## Parameters
    # - `text`: Romanized text to convert
    # - `romanizer`: RomanizationMap to use for conversion
    #
    # ## Returns
    # Array of phonemes
    private def convert_romanization_to_phonemes(text : String, romanizer : RomanizationMap) : Array(String)
      # Create reverse mapping
      reverse_romanization = Hash(String, String).new
      romanizer.mappings.each do |phoneme, romanization|
        reverse_romanization[romanization] = phoneme
      end
      
      phonemes = [] of String
      i = 0
      
      while i < text.size
        # Try longest matches first
        found_match = false
        
        # Look for multi-character romanizations (e.g., "th" -> "θ")
        (2..4).reverse_each do |length|
          next if i + length > text.size
          
          substring = text[i, length]
          if phoneme = reverse_romanization[substring]?
            phonemes << phoneme
            i += length
            found_match = true
            break
          end
        end
        
        # If no multi-character match, try single character
        unless found_match
          char = text[i].to_s
          phonemes << (reverse_romanization[char]? || char)
          i += 1
        end
      end
      
      phonemes
    end
  end
end