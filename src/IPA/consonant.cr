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
    end
end