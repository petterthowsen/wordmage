module WordMage::IPA
    ## the manner of articulation
    enum Manner
        Plosive
        Nasal
        Trill
        Tap # tap/flap
        Fricative
        LateralFricative
        Approximant
        LateralApproximant
        Click
    end

    ## the place of articulation
    enum Place
        Bilabial
        Labiodental
        Dental
        Alveolar
        Postalveolar
        Retroflex
        Palatal
        Velar
        Uvular
        Pharyngeal
        Glottal
        LabialVelar
        LabialPalatal
        Palatoalveolar
        AlveoloPalatal
        Epiglottal
    end
    
    ## A consonant phoneme
    class Consonant < Phoneme
        ## plosive, nasal, trill, tap, fricative, lateral-fricative, approximant, etc.
        property manner : Manner
        
        ## bilabial, labiodental, alveolar, postalveolar, retroflex, palatal, velar, uvular, pharyngeal, glottal
        property place  : Place

        ## true for [b d g v z …], false for [p t k f s …]
        property voiced      : Bool
    
        ## whether the consonant is aspirated
        property aspirated   : Bool = false  # [pʰ tʰ kʰ …]
        
        ## whether the consonant is nasal
        property nasal       : Bool = false  # [m n ɲ …]
        
        ## whether the consonant is lateral
        property lateral     : Bool = false  # [l ʎ ɫ …]
        
        ## whether the consonant is ejective
        property ejective    : Bool = false  # [pʼ tʼ …]
        
        ## whether the consonant is implosive
        property implosive   : Bool = false  # [ɓ ɗ …]
        
        ## whether the consonant is affricate
        property affricate   : Bool = false  # [ts ts̪ tʃ tʃ̪ tʂ tʂ̪ tɕ tɕ̪]

        def initialize(
            symbol : String,
            romanization : String,
            @manner : Manner,
            @place : Place,
            @voiced : Bool,
            @aspirated : Bool = false,
            @nasal : Bool = false,
            @lateral : Bool = false,
            @ejective : Bool = false,
            @implosive : Bool = false,
            @affricate : Bool = false
        )
            super(symbol, romanization, Category::CONSONANT)
        end

        ## Returns a human-readable name describing the consonant
        def name : String
            features = [] of String
            
            features << "aspirated" if aspirated
            features << "ejective" if ejective
            features << "implosive" if implosive
            features << "lateral" if lateral && !manner.to_s.includes?("Lateral")
            
            voicing = voiced ? "voiced" : "voiceless"
            
            # Convert enum names to match phonemes.txt format
            manner_str = case manner
                        when .plosive? then "plosive"
                        when .nasal? then "nasal"
                        when .trill? then "trill"
                        when .tap? then "tap"
                        when .fricative? then "fricative"
                        when .lateral_fricative? then "lateral fricative"
                        when .approximant? then "approximant"
                        when .lateral_approximant? then "lateral approximant"
                        when .click? then "click"
                        else manner.to_s.downcase
                        end
            
            place_str = case place
                       when .bilabial? then "bilabial"
                       when .labiodental? then "labiodental"
                       when .dental? then "dental"
                       when .alveolar? then "alveolar"
                       when .postalveolar? then "postalveolar"
                       when .retroflex? then "retroflex"
                       when .palatal? then "palatal"
                       when .velar? then "velar"
                       when .uvular? then "uvular"
                       when .pharyngeal? then "pharyngeal"
                       when .glottal? then "glottal"
                       when .labial_velar? then "labial-velar"
                       when .labial_palatal? then "labial-palatal"
                       when .palatoalveolar? then "palato-alveolar"
                       when .alveolo_palatal? then "alveolo-palatal"
                       when .epiglottal? then "epiglottal"
                       else place.to_s.downcase
                       end
            
            if affricate
                "#{voicing} #{place_str} affricate"
            else
                "#{voicing} #{place_str} #{manner_str}"
            end
        end
    end
end