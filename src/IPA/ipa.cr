require "json"
require "./phoneme"
require "./vowel"
require "./consonant"

module WordMage::IPA
    ## The basic phonemes of the International Phonetic Alphabet (IPA)
    BasicPhonemes = [
        # -- Vowels -- #
        Vowel.new("i", "i", :FullClose, :FullFront, rounded: false),
        Vowel.new("y", "y", :FullClose, :FullFront, rounded: true),
        Vowel.new("ɨ", "ɨ", :FullClose, :Central, rounded: false),
        Vowel.new("ʉ", "ʉ", :FullClose, :Central, rounded: true),
        Vowel.new("ɯ", "ɯ", :FullClose, :FullBack, rounded: false),
        Vowel.new("u", "u", :FullClose, :FullBack, rounded: true),
        Vowel.new("ɪ", "ɪ", :NearClose, :NearFront, rounded: false),
        Vowel.new("ʏ", "ʏ", :NearClose, :NearFront, rounded: true),
        Vowel.new("ʊ", "ʊ", :NearClose, :NearBack, rounded: true),
        Vowel.new("e", "e", :CloseMid, :FullFront, rounded: false),
        Vowel.new("ø", "ø", :CloseMid, :FullFront, rounded: true),
        Vowel.new("ɘ", "ɘ", :CloseMid, :Central, rounded: false),
        Vowel.new("ɵ", "ɵ", :CloseMid, :Central, rounded: true),
        Vowel.new("ɤ", "ɤ", :CloseMid, :FullBack, rounded: false),
        Vowel.new("o", "o", :CloseMid, :FullBack, rounded: true),
        Vowel.new("ə", "ə", :Mid, :Central, rounded: false),
        Vowel.new("ɛ", "ɛ", :OpenMid, :FullFront, rounded: false),
        Vowel.new("œ", "œ", :OpenMid, :FullFront, rounded: true),
        Vowel.new("ɜ", "ɜ", :OpenMid, :Central, rounded: false),
        Vowel.new("ɞ", "ɞ", :OpenMid, :Central, rounded: true),
        Vowel.new("ʌ", "ʌ", :OpenMid, :FullBack, rounded: false),
        Vowel.new("ɔ", "ɔ", :OpenMid, :FullBack, rounded: true),
        Vowel.new("æ", "æ", :NearOpen, :FullFront, rounded: false),
        Vowel.new("ɐ", "ɐ", :NearOpen, :Central, rounded: false),
        Vowel.new("a", "a", :FullOpen, :FullFront, rounded: false),
        Vowel.new("ä", "ä", :FullOpen, :FullFront, rounded: true),
        Vowel.new("ɑ", "ɑ", :FullOpen, :FullBack, rounded: false),
        Vowel.new("ɒ", "ɒ", :FullOpen, :FullBack, rounded: true),
        
        # -- Consonants -- #

        # Plosives
        Consonant.new("p", "p", :Plosive, :Bilabial, voiced: false),
        Consonant.new("b", "b", :Plosive, :Bilabial, voiced: true),
        Consonant.new("t", "t", :Plosive, :Alveolar, voiced: false),
        Consonant.new("d", "d", :Plosive, :Alveolar, voiced: true),
        Consonant.new("ʈ", "ʈ", :Plosive, :Retroflex, voiced: false),
        Consonant.new("ɖ", "ɖ", :Plosive, :Retroflex, voiced: true),
        Consonant.new("c", "c", :Plosive, :Palatal, voiced: false),
        Consonant.new("ɟ", "ɟ", :Plosive, :Palatal, voiced: true),
        Consonant.new("k", "k", :Plosive, :Velar, voiced: false),
        Consonant.new("g", "g", :Plosive, :Velar, voiced: true),
        Consonant.new("q", "q", :Plosive, :Uvular, voiced: false),
        Consonant.new("ɢ", "ɢ", :Plosive, :Uvular, voiced: true),
        Consonant.new("ʔ", "ʔ", :Plosive, :Glottal, voiced: false),

        # Nasals
        Consonant.new("m", "m", :Nasal, :Bilabial, voiced: true, nasal: true),
        Consonant.new("ɱ", "ɱ", :Nasal, :Labiodental, voiced: true, nasal: true),
        Consonant.new("n", "n", :Nasal, :Alveolar, voiced: true, nasal: true),
        Consonant.new("ɳ", "ɳ", :Nasal, :Retroflex, voiced: true, nasal: true),
        Consonant.new("ɲ", "ɲ", :Nasal, :Palatal, voiced: true, nasal: true),
        Consonant.new("ŋ", "ŋ", :Nasal, :Velar, voiced: true, nasal: true),
        Consonant.new("ɴ", "ɴ", :Nasal, :Uvular, voiced: true, nasal: true),

        # Trills
        Consonant.new("ʙ", "ʙ", :Trill, :Bilabial, voiced: true),
        Consonant.new("r", "r", :Trill, :Alveolar, voiced: true),
        Consonant.new("ʀ", "ʀ", :Trill, :Uvular, voiced: true),

        # Taps/Flaps
        Consonant.new("ɾ", "ɾ", :Tap, :Alveolar, voiced: true),
        Consonant.new("ɽ", "ɽ", :Tap, :Retroflex, voiced: true),

        # Fricatives
        Consonant.new("ɸ", "ɸ", :Fricative, :Bilabial, voiced: false),
        Consonant.new("β", "β", :Fricative, :Bilabial, voiced: true),
        Consonant.new("f", "f", :Fricative, :Labiodental, voiced: false),
        Consonant.new("v", "v", :Fricative, :Labiodental, voiced: true),
        Consonant.new("θ", "θ", :Fricative, :Dental, voiced: false),
        Consonant.new("ð", "ð", :Fricative, :Dental, voiced: true),
        Consonant.new("s", "s", :Fricative, :Alveolar, voiced: false),
        Consonant.new("z", "z", :Fricative, :Alveolar, voiced: true),
        Consonant.new("ʃ", "ʃ", :Fricative, :Postalveolar, voiced: false),
        Consonant.new("ʒ", "ʒ", :Fricative, :Postalveolar, voiced: true),
        Consonant.new("ʂ", "ʂ", :Fricative, :Retroflex, voiced: false),
        Consonant.new("ʐ", "ʐ", :Fricative, :Retroflex, voiced: true),
        Consonant.new("ç", "ç", :Fricative, :Palatal, voiced: false),
        Consonant.new("ʝ", "ʝ", :Fricative, :Palatal, voiced: true),
        Consonant.new("x", "x", :Fricative, :Velar, voiced: false),
        Consonant.new("ɣ", "ɣ", :Fricative, :Velar, voiced: true),
        Consonant.new("χ", "χ", :Fricative, :Uvular, voiced: false),
        Consonant.new("ʁ", "ʁ", :Fricative, :Uvular, voiced: true),
        Consonant.new("ħ", "ħ", :Fricative, :Pharyngeal, voiced: false),
        Consonant.new("ʕ", "ʕ", :Fricative, :Pharyngeal, voiced: true),
        Consonant.new("h", "h", :Fricative, :Glottal, voiced: false),
        Consonant.new("ɦ", "ɦ", :Fricative, :Glottal, voiced: true),

        # Lateral Fricatives
        Consonant.new("ɬ", "ɬ", :LateralFricative, :Alveolar, voiced: false, lateral: true),
        Consonant.new("ɮ", "ɮ", :LateralFricative, :Alveolar, voiced: true, lateral: true),

        # Approximants
        Consonant.new("ʋ", "ʋ", :Approximant, :Labiodental, voiced: true),
        Consonant.new("ɹ", "ɹ", :Approximant, :Alveolar, voiced: true),
        Consonant.new("ɻ", "ɻ", :Approximant, :Retroflex, voiced: true),
        Consonant.new("j", "j", :Approximant, :Palatal, voiced: true),
        Consonant.new("ɰ", "ɰ", :Approximant, :Velar, voiced: true),

        # Lateral Approximants
        Consonant.new("l", "l", :LateralApproximant, :Alveolar, voiced: true, lateral: true),
        Consonant.new("ɭ", "ɭ", :LateralApproximant, :Retroflex, voiced: true, lateral: true),
        Consonant.new("ʎ", "ʎ", :LateralApproximant, :Palatal, voiced: true, lateral: true),
        Consonant.new("ʟ", "ʟ", :LateralApproximant, :Velar, voiced: true, lateral: true),

        # Implosives
        Consonant.new("ɓ", "ɓ", :Plosive, :Bilabial, voiced: true, implosive: true),
        Consonant.new("ɗ", "ɗ", :Plosive, :Alveolar, voiced: true, implosive: true),
        Consonant.new("ʄ", "ʄ", :Plosive, :Palatal, voiced: true, implosive: true),
        Consonant.new("ɠ", "ɠ", :Plosive, :Velar, voiced: true, implosive: true),
        Consonant.new("ʛ", "ʛ", :Plosive, :Uvular, voiced: true, implosive: true),

        # Ejectives
        Consonant.new("pʼ", "p'", :Plosive, :Bilabial, voiced: false, ejective: true),
        Consonant.new("tʼ", "t'", :Plosive, :Alveolar, voiced: false, ejective: true),
        Consonant.new("kʼ", "k'", :Plosive, :Velar, voiced: false, ejective: true),
        Consonant.new("sʼ", "s'", :Fricative, :Alveolar, voiced: false, ejective: true),

        # Affricates
        Consonant.new("t͡s", "ts", :Plosive, :Alveolar, voiced: false, affricate: true),
        Consonant.new("d͡z", "dz", :Plosive, :Alveolar, voiced: true, affricate: true),
        Consonant.new("t͡ʃ", "tʃ", :Plosive, :Postalveolar, voiced: false, affricate: true),
        Consonant.new("d͡ʒ", "dʒ", :Plosive, :Postalveolar, voiced: true, affricate: true),

        # Clicks
        Consonant.new("ʘ", "ʘ", :Click, :Bilabial, voiced: false),
        Consonant.new("ǀ", "ǀ", :Click, :Dental, voiced: false),
        Consonant.new("ǃ", "ǃ", :Click, :Postalveolar, voiced: false),
        Consonant.new("ǂ", "ǂ", :Click, :Palatoalveolar, voiced: false),
        Consonant.new("ǁ", "ǁ", :Click, :Alveolar, voiced: false, lateral: true),

        # Other Consonants
        Consonant.new("ʍ", "ʍ", :Fricative, :LabialVelar, voiced: false),
        Consonant.new("w", "w", :Approximant, :LabialVelar, voiced: true),
        Consonant.new("ɥ", "ɥ", :Approximant, :LabialPalatal, voiced: true),
        Consonant.new("ʜ", "ʜ", :Fricative, :Epiglottal, voiced: false),
        Consonant.new("ʢ", "ʢ", :Fricative, :Epiglottal, voiced: true),
        Consonant.new("ʡ", "ʡ", :Plosive, :Epiglottal, voiced: false),
        Consonant.new("ɕ", "ɕ", :Fricative, :AlveoloPalatal, voiced: false),
        Consonant.new("ʑ", "ʑ", :Fricative, :AlveoloPalatal, voiced: true),
        Consonant.new("ɺ", "ɺ", :Tap, :Alveolar, voiced: true, lateral: true),
        Consonant.new("t͡ɕ", "tɕ", :Plosive, :AlveoloPalatal, voiced: false, affricate: true),
        Consonant.new("d͡ʑ", "dʑ", :Plosive, :AlveoloPalatal, voiced: true, affricate: true),
        Consonant.new("ʈ͡ʂ", "tʂ", :Plosive, :Retroflex, voiced: false, affricate: true),
        Consonant.new("ɖ͡ʐ", "dʐ", :Plosive, :Retroflex, voiced: true, affricate: true)
    ]

end