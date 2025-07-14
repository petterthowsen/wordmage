module WordMage::IPA
    ## The category of a phoneme
    enum Category
        VOWEL
        CONSONANT
    end
    
    ## A phoneme
    ## extended by WordMage::IPA::Vowel and WordMage::IPA::Consonant
    class Phoneme
        include JSON::Serializable
        
        ## The phonetic symbol
        property symbol : String
        
        ## The most common romanized form
        property romanization : String

        ## The category of the phoneme
        property category : Category

        def initialize(@symbol : String, @romanization : String, @category : Category)
        end
    end
end