require "./spec_helper"

describe WordMage::RomanizationMap do
  describe "#initialize" do
    it "creates an empty romanization map" do
      romanizer = WordMage::RomanizationMap.new
      romanizer.mappings.should eq({} of String => String)
    end

    it "creates a romanization map with initial mappings" do
      mappings = {"p" => "p", "t" => "th", "a" => "a"}
      romanizer = WordMage::RomanizationMap.new(mappings)
      romanizer.mappings.should eq(mappings)
    end
  end

  describe "#add_mapping" do
    it "adds a phoneme to romanization mapping" do
      romanizer = WordMage::RomanizationMap.new
      romanizer.add_mapping("p", "ph")
      
      romanizer.mappings["p"].should eq("ph")
    end

    it "overwrites existing mappings" do
      romanizer = WordMage::RomanizationMap.new({"p" => "p"})
      romanizer.add_mapping("p", "ph")
      
      romanizer.mappings["p"].should eq("ph")
    end
  end

  describe "#romanize" do
    it "converts phonemes to romanized form" do
      mappings = {
        "p" => "p",
        "t" => "th", 
        "a" => "a",
        "e" => "e"
      }
      romanizer = WordMage::RomanizationMap.new(mappings)
      
      phonemes = ["p", "a", "t", "e"]
      result = romanizer.romanize(phonemes)
      
      result.should eq("pathe")
    end

    it "uses original phoneme when no mapping exists" do
      mappings = {"p" => "ph"}
      romanizer = WordMage::RomanizationMap.new(mappings)
      
      phonemes = ["p", "a", "t"]
      result = romanizer.romanize(phonemes)
      
      result.should eq("phat")  # "p" -> "ph", "a" -> "a", "t" -> "t"
    end

    it "handles empty phoneme arrays" do
      romanizer = WordMage::RomanizationMap.new
      result = romanizer.romanize([] of String)
      
      result.should eq("")
    end

    it "handles complex mappings" do
      mappings = {
        "θ" => "th",
        "ʃ" => "sh", 
        "tʃ" => "ch",
        "a" => "a",
        "ɛ" => "e"
      }
      romanizer = WordMage::RomanizationMap.new(mappings)
      
      phonemes = ["θ", "ɛ", "ʃ", "a"]
      result = romanizer.romanize(phonemes)
      
      result.should eq("thesha")
    end

    it "handles multi-character phonemes and romanizations" do
      mappings = {
        "ng" => "ñ",
        "th" => "þ",
        "aa" => "ā"
      }
      romanizer = WordMage::RomanizationMap.new(mappings)
      
      phonemes = ["th", "aa", "ng"]
      result = romanizer.romanize(phonemes)
      
      result.should eq("þāñ")
    end

    it "preserves order of phonemes" do
      mappings = {"1" => "a", "2" => "b", "3" => "c"}
      romanizer = WordMage::RomanizationMap.new(mappings)
      
      phonemes = ["3", "2", "1"]
      result = romanizer.romanize(phonemes)
      
      result.should eq("cba")
    end
  end
end