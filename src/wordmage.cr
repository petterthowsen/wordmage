require "log"
require "./phoneme_set"
require "./syllable_template"
require "./word_spec"
require "./romanization_map"
require "./generator"
require "./generator_builder"
require "./word_analysis"
require "./word_analyzer"
require "./analysis"
require "./analyzer"
require "./vowel_harmony"
require "./IPA/ipa"

module WordMage
  VERSION = "0.9.1"
  Log = ::Log.for(self)
end
