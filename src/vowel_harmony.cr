require "json"

module WordMage
  # Defines vowel harmony rules and transition preferences.
  #
  # VowelHarmony manages which vowels can follow other vowels, with configurable
  # strictness from absolute rules (traditional vowel harmony) to loose statistical
  # preferences (vowel transitions). This allows modeling both strict languages
  # like Finnish and flexible patterns like constructed languages.
  #
  # ## Example
  # ```crystal
  # # Strict harmony (Finnish-style)
  # harmony = VowelHarmony.new({
  #   "a" => {"a" => 1.0, "o" => 1.0, "u" => 0.0},  # Back vowels only
  #   "e" => {"e" => 1.0, "i" => 1.0, "y" => 1.0}   # Front vowels only
  # }, strength: 1.0)
  #
  # # Loose transitions (Elvish-style)
  # harmony = VowelHarmony.new({
  #   "a" => {"e" => 0.8, "o" => 0.6, "u" => 0.2}   # Preferences
  # }, strength: 0.7)
  # ```
  class VowelHarmony
    include JSON::Serializable

    # Harmony rules: first vowel -> {second vowel -> preference weight}
    property rules : Hash(String, Hash(String, Float32))

    # Harmony strength: 0.0 = ignore rules, 1.0 = absolute rules
    property strength : Float32

    # Default preference for vowels not in rules
    property default_preference : Float32

    # Creates a new VowelHarmony configuration.
    #
    # ## Parameters
    # - `rules`: Hash mapping vowels to their preferred followers
    # - `strength`: How strictly to follow rules (0.0-1.0)
    # - `default_preference`: Default weight for unspecified transitions
    def initialize(@rules : Hash(String, Hash(String, Float32)) = Hash(String, Hash(String, Float32)).new, 
                   @strength : Float32 = 0.0_f32, @default_preference : Float32 = 0.5_f32)
    end

    # Gets the preference weight for a vowel transition.
    #
    # ## Parameters
    # - `from_vowel`: The current vowel
    # - `to_vowel`: The potential next vowel
    #
    # ## Returns
    # Float32 preference weight (0.0-1.0+)
    #
    # ## Example
    # ```crystal
    # weight = harmony.get_transition_weight("a", "e")  # 0.8
    # ```
    def get_transition_weight(from_vowel : String, to_vowel : String) : Float32
      return @default_preference if @strength == 0.0_f32
      
      if vowel_rules = @rules[from_vowel]?
        if preference = vowel_rules[to_vowel]?
          # Apply strength: interpolate between default and rule preference
          @default_preference + (@strength * (preference - @default_preference))
        else
          @default_preference
        end
      else
        @default_preference
      end
    end

    # Selects a vowel based on harmony rules and weights.
    #
    # ## Parameters
    # - `from_vowel`: The current vowel (nil if first vowel)
    # - `available_vowels`: Array of possible vowels to choose from
    #
    # ## Returns
    # String representing the selected vowel
    #
    # ## Example
    # ```crystal
    # next_vowel = harmony.select_vowel("a", ["e", "i", "o", "u"])
    # ```
    def select_vowel(from_vowel : String?, available_vowels : Array(String)) : String
      return available_vowels.sample if from_vowel.nil? || @strength == 0.0_f32
      
      # Calculate weights for each available vowel
      weights = available_vowels.map do |vowel|
        {vowel, get_transition_weight(from_vowel, vowel)}
      end
      
      # Weighted random selection
      total_weight = weights.sum { |_, weight| weight }
      return available_vowels.sample if total_weight <= 0.0_f32
      
      target = Random.rand * total_weight
      current_weight = 0.0_f32
      
      weights.each do |vowel, weight|
        current_weight += weight
        return vowel if current_weight >= target
      end
      
      # Fallback
      weights.first.first
    end

    # Adds or updates a harmony rule.
    #
    # ## Parameters
    # - `from_vowel`: The source vowel
    # - `to_vowel`: The target vowel
    # - `preference`: Preference weight (0.0-1.0+)
    #
    # ## Example
    # ```crystal
    # harmony.add_rule("a", "e", 0.8)  # "a" prefers "e"
    # ```
    def add_rule(from_vowel : String, to_vowel : String, preference : Float32)
      @rules[from_vowel] ||= Hash(String, Float32).new
      @rules[from_vowel][to_vowel] = preference
    end

    # Checks if harmony rules are defined.
    #
    # ## Returns
    # `true` if rules exist and strength > 0, `false` otherwise
    def active? : Bool
      @strength > 0.0_f32 && !@rules.empty?
    end

    # Returns the most preferred vowels for a given source vowel.
    #
    # ## Parameters
    # - `from_vowel`: The source vowel
    # - `count`: Number of top preferences to return (default: 3)
    #
    # ## Returns
    # Array of vowel strings ordered by preference
    def preferred_vowels(from_vowel : String, count : Int32 = 3) : Array(String)
      return [] of String unless @rules[from_vowel]?
      
      @rules[from_vowel].to_a
        .sort_by { |_, weight| -weight }
        .first(count)
        .map { |vowel, _| vowel }
    end

    # Returns the least preferred vowels for a given source vowel.
    #
    # ## Parameters
    # - `from_vowel`: The source vowel
    # - `count`: Number of bottom preferences to return (default: 3)
    #
    # ## Returns
    # Array of vowel strings ordered by least preference
    def avoided_vowels(from_vowel : String, count : Int32 = 3) : Array(String)
      return [] of String unless @rules[from_vowel]?
      
      @rules[from_vowel].to_a
        .sort_by { |_, weight| weight }
        .first(count)
        .map { |vowel, _| vowel }
    end

    # Analyzes the harmony rules for consistency.
    #
    # ## Returns
    # Hash with analysis metrics
    def analyze_consistency : Hash(String, Float32)
      return {"consistency" => 0.0_f32} if @rules.empty?
      
      total_rules = 0
      high_preference_count = 0
      low_preference_count = 0
      
      @rules.each do |_, preferences|
        preferences.each do |_, weight|
          total_rules += 1
          high_preference_count += 1 if weight > 0.7_f32
          low_preference_count += 1 if weight < 0.3_f32
        end
      end
      
      {
        "consistency" => total_rules > 0 ? (high_preference_count + low_preference_count).to_f32 / total_rules : 0.0_f32,
        "total_rules" => total_rules.to_f32,
        "strong_preferences" => high_preference_count.to_f32,
        "strong_avoidances" => low_preference_count.to_f32
      }
    end

    # Generates a summary of the vowel harmony configuration.
    #
    # ## Returns
    # String describing the harmony setup
    def summary : String
      if !active?
        return "Vowel harmony disabled (strength: #{@strength})"
      end
      
      lines = [] of String
      lines << "Vowel Harmony (strength: #{@strength})"
      lines << "Rules defined for: #{@rules.keys.join(", ")}"
      
      @rules.each do |from_vowel, preferences|
        preferred = preferences.select { |_, w| w > 0.6_f32 }.keys
        avoided = preferences.select { |_, w| w < 0.4_f32 }.keys
        
        unless preferred.empty?
          lines << "  #{from_vowel} → #{preferred.join(", ")} (preferred)"
        end
        unless avoided.empty?
          lines << "  #{from_vowel} ↛ #{avoided.join(", ")} (avoided)"
        end
      end
      
      lines.join("\n")
    end
  end
end