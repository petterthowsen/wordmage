module WordMage
  # Maps phonemes to their written/romanized representations.
  #
  # RomanizationMap handles the conversion from internal phoneme representations
  # to their final written form. This allows using IPA or custom phoneme symbols
  # internally while outputting readable text.
  #
  # ## Example
  # ```crystal
  # romanizer = RomanizationMap.new({
  #   "p" => "p",
  #   "θ" => "th",    # IPA theta -> "th"
  #   "ʃ" => "sh",    # IPA esh -> "sh"
  #   "a" => "a"
  # })
  # word = romanizer.romanize(["p", "θ", "a"])  # "ptha"
  # ```
  class RomanizationMap
    property mappings : Hash(String, String)

    # Creates a new romanization map.
    #
    # ## Parameters
    # - `mappings`: Hash mapping phonemes to their written form (optional)
    def initialize(@mappings = Hash(String, String).new)
    end

    # Adds or updates a phoneme-to-romanization mapping.
    #
    # ## Parameters
    # - `phoneme`: The internal phoneme representation
    # - `romanization`: The written form to output
    def add_mapping(phoneme : String, romanization : String)
      @mappings[phoneme] = romanization
    end

    # Converts an array of phonemes to written text.
    #
    # ## Parameters
    # - `phonemes`: Array of phoneme strings to convert
    #
    # ## Returns
    # String with phonemes converted to their romanized form.
    # Unmapped phonemes are left as-is.
    #
    # ## Example
    # ```crystal
    # romanizer.romanize(["p", "θ", "a"])  # "ptha" (if θ -> "th")
    # ```
    def romanize(phonemes : Array(String)) : String
      phonemes.map { |p| @mappings[p]? || p }.join
    end
  end
end