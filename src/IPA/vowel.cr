require "json"
require "./phoneme"

module WordMage::IPA
    
    enum VowelHeight
        FullClose
        NearClose
        CloseMid
        Mid
        OpenMid
        NearOpen
        FullOpen
    end
    
    enum VowelBackness
        FullFront
        NearFront
        Central
        NearBack
        FullBack
    end

    ## A vowel phoneme
    class Vowel < Phoneme

        ## the height of the vowel
        property height   : VowelHeight

        ## the backness of the vowel
        property backness : VowelBackness
        
        ## whether the vowel is rounded
        property rounded  : Bool
    
        ## whether the vowel is nasalized
        property nasal    : Bool   = false
        
        ## whether the vowel is lengthened
        property lengthened : Bool = false
        
        ## whether the vowel is rhotic
        property rhotic   : Bool   = false

        def initialize(
            symbol : String,
            romanization : String,
            @height : VowelHeight,
            @backness : VowelBackness,
            @rounded : Bool,
            @nasal : Bool = false,
            @lengthened : Bool = false,
            @rhotic : Bool = false
        )
            super(symbol, romanization, Category::VOWEL)
        end

         ## whether the vowel is open (height is FullOpen, OpenMid, or NearOpen)
         def open?
            [VowelHeight::FullOpen, VowelHeight::OpenMid, VowelHeight::NearOpen].include?(height)
        end

        ## whether the vowel is close (height is FullClose, NearClose, or CloseMid)
        def close?
            [VowelHeight::FullClose, VowelHeight::NearClose, VowelHeight::CloseMid].include?(height)
        end

        ## whether the vowel is front (backness is FullFront or NearFront)
        def front?
            [VowelBackness::FullFront, VowelBackness::NearFront].include?(backness)
        end

        def back?
            [VowelBackness::FullBack, VowelBackness::NearBack].include?(backness)
        end

        def central?
            backness == VowelBackness::Central
        end

        def rounded?
            rounded
        end

        def nasal?
            nasal
        end

        def lengthened?
            lengthened
        end

        def rhotic?
            rhotic
        end

        def front_rounded?
            front? && rounded?
        end

        def back_rounded?
            back? && rounded?
        end

        def front_nasal?
            front? && nasal?
        end

        def back_nasal?
            back? && nasal?
        end

        def front_lengthened?
            front? && lengthened?
        end

        def back_lengthened?
            back? && lengthened?
        end

        def front_rhotic?
            front? && rhotic?
        end

        def back_rhotic?
            back? && rhotic?
        end
    end
end